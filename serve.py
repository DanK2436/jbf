import os
import sys
import json
import socket
import http.server
import socketserver
import urllib.request
import urllib.error
import random
from datetime import date
from urllib.parse import unquote, urlsplit

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BIND_HOST = os.environ.get('JBF_BIND_HOST', '127.0.0.1')
LOCAL_IP = get_local_ip()
SECURITY_CSP = (
    "default-src 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'none'; "
    "form-action 'self'; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; "
    "style-src 'self' https://cdn.jsdelivr.net https://fonts.googleapis.com 'unsafe-inline'; "
    "font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net data:; "
    "img-src 'self' data: blob: https:; "
    "connect-src 'self' https://*.supabase.co https://cdn.jsdelivr.net "
    "http://127.0.0.1:* http://localhost:*"
)
PUBLIC_TREES = {'JBF Public', 'JBF Client', 'assets', 'js'}

# Lecture des clés depuis backend/.env (sécurisé, non committé)
def load_env_file():
    env_path = os.path.join(BASE_DIR, 'backend', '.env')
    env_vars = {}
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env_vars[k.strip()] = v.strip()
    return env_vars

_env = load_env_file()
BREVO_API_KEY = os.environ.get('BREVO_API_KEY') or _env.get('BREVO_API_KEY', '')
RESEND_API_KEY = os.environ.get('RESEND_API_KEY') or _env.get('RESEND_API_KEY', '')
ADMIN_OFFICIAL_EMAIL = (os.environ.get('ADMIN_OFFICIAL_EMAIL') or _env.get('ADMIN_OFFICIAL_EMAIL', 'services@admin.jbf')).strip().lower()
if 'ADMIN_OFFICIAL_PASSWORD' in os.environ:
    ADMIN_OFFICIAL_PASSWORD = (os.environ.get('ADMIN_OFFICIAL_PASSWORD') or '').strip()
else:
    ADMIN_OFFICIAL_PASSWORD = (_env.get('ADMIN_OFFICIAL_PASSWORD') or '').strip()
SUPABASE_URL = os.environ.get('SUPABASE_URL') or _env.get('SUPABASE_URL', 'https://dvzwqxcaiagczyonrhsg.supabase.co')
SUPABASE_ANON_KEY = os.environ.get('SUPABASE_ANON_KEY') or _env.get('SUPABASE_ANON_KEY', '')
DAILY_LIMIT = 380

mail_stats = {'date': str(date.today()), 'brevo': 0, 'resend': 0, 'total': 0}

cached_brevo_sender = None

def get_brevo_sender():
    global cached_brevo_sender
    if cached_brevo_sender:
        return cached_brevo_sender
    try:
        url = 'https://api.brevo.com/v3/senders'
        req = urllib.request.Request(url, headers={'api-key': BREVO_API_KEY, 'accept': 'application/json', 'User-Agent': 'JBF-Backend/1.0'})
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode())
            senders = data.get('senders', [])
            for s in senders:
                if s.get('active'):
                    cached_brevo_sender = {'name': 'JBF SERVICES', 'email': s.get('email')}
                    print(f"[JBF Mail] Expéditeur vérifié Brevo détecté : {s.get('email')}", flush=True)
                    return cached_brevo_sender
    except Exception as e:
        print(f"[JBF Mail] Détection expéditeur Brevo : {e}", flush=True)
    
    cached_brevo_sender = {'name': 'JBF SERVICES', 'email': 'dankande3@gmail.com'}
    return cached_brevo_sender

def send_via_brevo(to_email, subject, html):
    url = 'https://api.brevo.com/v3/smtp/email'
    headers = {
        'api-key': BREVO_API_KEY,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'JBF-Backend/1.0'
    }
    sender = get_brevo_sender()
    payload = json.dumps({
        'sender': sender,
        'to': [{'email': to_email}],
        'subject': subject,
        'htmlContent': html
    }).encode('utf-8')
    
    req = urllib.request.Request(url, data=payload, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode('utf-8')
            return {'success': True, 'provider': 'brevo', 'code': resp.status, 'body': body}
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='ignore')
        return {'success': False, 'provider': 'brevo', 'code': e.code, 'error': body}
    except Exception as e:
        return {'success': False, 'provider': 'brevo', 'error': str(e)}

def send_via_resend(to_email, subject, html):
    url = 'https://api.resend.com/emails'
    headers = {
        'Authorization': f'Bearer {RESEND_API_KEY}',
        'Content-Type': 'application/json',
        'User-Agent': 'JBF-Backend/1.0'
    }
    payload = json.dumps({
        'from': 'JBF SERVICES <onboarding@resend.dev>',
        'to': [to_email],
        'subject': subject,
        'html': html
    }).encode('utf-8')
    
    req = urllib.request.Request(url, data=payload, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return {'success': True, 'provider': 'resend', 'code': resp.status}
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8', errors='ignore')
        return {'success': False, 'provider': 'resend', 'code': e.code, 'error': body}
    except Exception as e:
        return {'success': False, 'provider': 'resend', 'error': str(e)}

def send_email_server(to_email, subject, html, preferred=None):
    today = str(date.today())
    if mail_stats['date'] != today:
        mail_stats['date'] = today
        mail_stats['brevo'] = 0
        mail_stats['resend'] = 0
        mail_stats['total'] = 0
    
    if mail_stats['total'] >= DAILY_LIMIT:
        return {'success': False, 'error': f'Quota quotidien de {DAILY_LIMIT} emails atteint.'}
    
    max_brevo = int(DAILY_LIMIT * 0.8) # 304
    max_resend = DAILY_LIMIT - max_brevo # 76
    
    if mail_stats['brevo'] >= max_brevo:
        primary = 'resend'
    elif mail_stats['resend'] >= max_resend:
        primary = 'brevo'
    elif preferred in ('brevo', 'resend'):
        primary = preferred
    else:
        primary = 'brevo' if random.random() < 0.8 else 'resend'
        
    secondary = 'resend' if primary == 'brevo' else 'brevo'
    
    # 1. Tentative avec le prestataire primaire
    res = send_via_brevo(to_email, subject, html) if primary == 'brevo' else send_via_resend(to_email, subject, html)
    if res.get('success'):
        mail_stats[primary] += 1
        mail_stats['total'] += 1
        print(f"[JBF Mail Server] Succès via {primary.upper()} à {to_email} (Quota: {mail_stats['total']}/{DAILY_LIMIT})")
        sys.stdout.flush()
        return res
        
    print(f"[JBF Mail Server] Échec {primary.upper()}, basculement sur {secondary.upper()}...")
    sys.stdout.flush()
    
    # 2. Tentative avec le prestataire secondaire (failover)
    res2 = send_via_brevo(to_email, subject, html) if secondary == 'brevo' else send_via_resend(to_email, subject, html)
    if res2.get('success'):
        mail_stats[secondary] += 1
        mail_stats['total'] += 1
        print(f"[JBF Mail Server] Succès via prestataire de secours {secondary.upper()} à {to_email}")
        sys.stdout.flush()
        return res2
        
    print(f"[JBF Mail Server] Échec des deux prestataires! Brevo: {res if primary=='brevo' else res2} | Resend: {res2 if primary=='brevo' else res}")
    sys.stdout.flush()
    return {
        'success': False,
        'error': 'Impossible de transmettre le courriel via Brevo et Resend.',
        'details': {primary: res, secondary: res2}
    }

def normalize_public_path(raw_path):
    """Décode l'URL et refuse traversée, dotfiles et octets nuls."""
    path = urlsplit(raw_path or '').path
    if '\x00' in path or '%00' in path.lower():
        return None
    decoded = path
    for _ in range(5):
        nxt = unquote(decoded)
        if nxt == decoded:
            break
        decoded = nxt
    if '\x00' in decoded or '\\' in decoded:
        return None
    parts = []
    for part in decoded.split('/'):
        if part in ('', '.'):
            continue
        if part == '..' or part.startswith('.'):
            return None
        parts.append(part)
    return parts


def public_file_allowed(parts):
    if not parts:
        return False
    if len(parts) == 1 and parts[0] == 'index.html':
        return True
    if parts[0] in PUBLIC_TREES:
        return True
    if parts[0] == 'supabase' and len(parts) == 2 and parts[1].endswith('.js'):
        return True
    return False


def resolve_public_file(base_dir, parts):
    if not public_file_allowed(parts):
        return None
    root = os.path.realpath(base_dir)
    candidate = os.path.realpath(os.path.join(root, *parts))
    try:
        if os.path.commonpath([root, candidate]) != root:
            return None
    except ValueError:
        return None
    if os.path.isdir(candidate):
        candidate = os.path.realpath(os.path.join(candidate, 'index.html'))
        try:
            if os.path.commonpath([root, candidate]) != root:
                return None
        except ValueError:
            return None
    if not os.path.isfile(candidate):
        return None
    name = os.path.basename(candidate).lower()
    if name.startswith('.') or name.endswith(('.env', '.pem', '.key', '.sql', '.sqlite', '.db')):
        return None
    return candidate


def admin_password_ok(configured, supplied):
    secret = (configured or '').strip()
    given = supplied or ''
    if not secret or not str(given).strip():
        return False
    return given == secret or str(given).strip() == secret


class JBFRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        path = urlsplit(self.path or '').path
        if not path.startswith('/api/mail/'):
            self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Content-Security-Policy', SECURITY_CSP)
        self.send_header('X-Frame-Options', 'DENY')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'strict-origin-when-cross-origin')
        super().end_headers()

    def _client_is_loopback(self):
        host = self.client_address[0]
        return host in ('127.0.0.1', '::1') or host.startswith('::ffff:127.0.0.1')

    def _mail_caller_allowed(self):
        if not self._client_is_loopback():
            return False
        sec = (self.headers.get('Sec-Fetch-Site') or '').lower()
        if sec == 'same-origin':
            return True
        origin = self.headers.get('Origin') or ''
        port = self.server.server_address[1]
        return origin in (f'http://127.0.0.1:{port}', f'http://localhost:{port}')

    def _send_json(self, status, payload):
        body = json.dumps(payload).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _serve_public_file(self):
        parts = normalize_public_path(self.path)
        target = resolve_public_file(BASE_DIR, parts) if parts is not None else None
        if parts is None or not public_file_allowed(parts):
            self.send_error(403, 'Accès interdit')
            return
        if not target:
            self.send_error(404, 'Introuvable')
            return
        try:
            with open(target, 'rb') as handle:
                data = handle.read()
        except OSError:
            self.send_error(404, 'Introuvable')
            return
        self.send_response(200)
        self.send_header('Content-Type', self.guess_type(target))
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        if self.command != 'HEAD':
            self.wfile.write(data)

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        path = urlsplit(self.path or '').path
        if path in ('/', ''):
            self.send_response(302)
            self.send_header('Location', '/JBF%20Public/index.html')
            self.end_headers()
            return
        if path == '/api/config':
            self._send_json(200, {
                'supabaseUrl': SUPABASE_URL,
                'supabaseAnonKey': SUPABASE_ANON_KEY
            })
            return
        self._serve_public_file()

    def do_POST(self):
        if urlsplit(self.path or '').path == '/api/mail/send':
            self._send_json(403, {
                'success': False,
                'error': "Relais de courriel arbitraire désactivé : aucun contrôle serveur authentifié. Origin, Sec-Fetch-Site et l'adresse loopback ne suffisent pas."
            })
            return

        elif self.path == '/api/admin/login':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(content_length)
                payload = json.loads(body.decode('utf-8'))

                email = (payload.get('email') or '').strip().lower()
                password = payload.get('password') or ''

                if not email or not password:
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'success': False, 'error': 'Email et mot de passe requis.'}).encode('utf-8'))
                    return

                is_email_match = (email == ADMIN_OFFICIAL_EMAIL)
                is_pass_match = admin_password_ok(ADMIN_OFFICIAL_PASSWORD, password)

                if is_email_match and is_pass_match:
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({
                        'success': True,
                        'name': 'Direction Générale JBF SERVICES',
                        'email': ADMIN_OFFICIAL_EMAIL,
                        'role': 'Super Administrateur',
                        'site': 'Lubumbashi (Siège Central)',
                        'avatar': 'DG',
                        'permissions': ['*'],
                        'token': f'jbf-admin-session-{int(random.random()*1e9)}'
                    }).encode('utf-8'))
                    return
                else:
                    self.send_response(401)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'success': False, 'error': 'Identifiants administrateur invalides.'}).encode('utf-8'))
                    return
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode('utf-8'))
                return

        self.send_response(404)
        self.end_headers()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == '__main__':
    os.chdir(BASE_DIR)
    with ReusableTCPServer((BIND_HOST, PORT), JBFRequestHandler) as httpd:
        print("=" * 60)
        print("   JBF SERVICES SARL — SERVEUR LOCAL DEMARRE AVEC SUCCES")
        print("=" * 60)
        print(f"  Accueil Public   : http://localhost:{PORT}/JBF%20Public/")
        print(f"  Espace Client    : http://localhost:{PORT}/JBF%20Client/")
        print(f"  Espace Admin     : http://localhost:{PORT}/JBF%20Admin/")
        print(f"  Espace Membre    : http://localhost:{PORT}/JBF%20Membre/")
        print(f"  Acces Reseau IP  : http://{LOCAL_IP}:{PORT}/")
        print(f"  API Mail Relais  : http://localhost:{PORT}/api/mail/send")
        print("=" * 60)
        sys.stdout.flush()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nArret du serveur.")
            httpd.server_close()
