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
LOCAL_IP = get_local_ip()

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
ADMIN_OFFICIAL_PASSWORD = os.environ.get('ADMIN_OFFICIAL_PASSWORD') or _env.get('ADMIN_OFFICIAL_PASSWORD', 'Services+243JBF')
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

class JBFRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path in ('/', ''):
            self.send_response(302)
            self.send_header('Location', '/JBF%20Public/index.html')
            self.end_headers()
            return
        elif self.path == '/api/config':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            data = {
                'supabaseUrl': SUPABASE_URL,
                'supabaseAnonKey': SUPABASE_ANON_KEY
            }
            self.wfile.write(json.dumps(data).encode('utf-8'))
            return
        super().do_GET()

    def do_POST(self):
        if self.path == '/api/mail/send':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(content_length)
                payload = json.loads(body.decode('utf-8'))
                
                to_email = payload.get('to')
                subject = payload.get('subject')
                html = payload.get('html')
                preferred = payload.get('provider')
                
                if not to_email or not subject or not html:
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'success': False, 'error': 'Champs obligatoires manquants (to, subject, html)'}).encode('utf-8'))
                    return
                
                import re
                otp_match = re.search(r'\b(\d{6})\b', (subject or '') + ' ' + (html or ''))
                if otp_match:
                    print(f"\n============================================================")
                    print(f"🔑 [JBF OTP CONSOLE] CODE DE CONNEXION : {otp_match.group(1)} (POUR: {to_email})")
                    print(f"============================================================\n", flush=True)

                result = send_email_server(to_email, subject, html, preferred)
                status_code = 200 if result.get('success') else 500
                self.send_response(status_code)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(result).encode('utf-8'))
                return
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode('utf-8'))
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
                is_pass_match = (password == ADMIN_OFFICIAL_PASSWORD or password.strip() == ADMIN_OFFICIAL_PASSWORD.strip())

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

os.chdir(BASE_DIR)

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == '__main__':
    with ReusableTCPServer(("0.0.0.0", PORT), JBFRequestHandler) as httpd:
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
