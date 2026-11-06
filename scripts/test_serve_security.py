#!/usr/bin/env python3
"""Contrôles du serveur local : fichiers, admin, OTP, relais. Secrets factices uniquement."""
import http.client
import json
import os
import sys
import tempfile
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

FAKE_SECRET = 'FIXTURE_ONLY=not-a-real-secret'
FAKE_OTP = '246813'
FAKE_ADMIN_PASSWORD = 'fixture-pass-not-secret'


def fail(message):
    print('ÉCHEC', message)
    sys.exit(1)


import serve  # noqa: E402

if os.environ.get('JBF_BIND_HOST', '127.0.0.1') != '127.0.0.1' and 'JBF_BIND_HOST' not in os.environ:
    fail('hôte par défaut inattendu')
if serve.BIND_HOST != os.environ.get('JBF_BIND_HOST', '127.0.0.1'):
    fail('BIND_HOST ne suit pas la valeur locale par défaut')
if '0.0.0.0' == serve.BIND_HOST:
    fail('le serveur écoute toutes les interfaces par défaut')


def build_fixture():
    tmp = tempfile.TemporaryDirectory()
    base = Path(tmp.name)
    (base / 'backend').mkdir()
    (base / 'backend' / '.env').write_text(FAKE_SECRET + '\n', encoding='utf-8')
    (base / '.git').mkdir()
    (base / '.git' / 'HEAD').write_text('ref: refs/heads/test\n', encoding='utf-8')
    (base / 'JBF Public').mkdir()
    (base / 'JBF Public' / 'index.html').write_text('hello-public', encoding='utf-8')
    (base / 'JBF Public' / '.secret').write_text(FAKE_SECRET, encoding='utf-8')
    (base / 'assets').mkdir()
    (base / 'assets' / 'logo.txt').write_text('logo', encoding='utf-8')
    (base / 'index.html').write_text('root', encoding='utf-8')
    return tmp, base


def start_server(base):
    serve.BASE_DIR = str(base)
    serve.JBFRequestHandler.log_message = lambda *args, **kwargs: None
    httpd = serve.ReusableTCPServer(('127.0.0.1', 0), serve.JBFRequestHandler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    return httpd


def request(port, method, path, body=None, headers=None):
    conn = http.client.HTTPConnection('127.0.0.1', port, timeout=5)
    data = None if body is None else json.dumps(body).encode('utf-8')
    hdrs = {'Content-Type': 'application/json'}
    if headers:
        hdrs.update(headers)
    conn.request(method, path, body=data, headers=hdrs)
    resp = conn.getresponse()
    payload = resp.read()
    status = resp.status
    header_csp = resp.getheader('Content-Security-Policy') or ''
    frame = resp.getheader('X-Frame-Options') or ''
    conn.close()
    return status, payload, header_csp, frame


def main():
    for configured, supplied, expected in (
        ('', 'anything', False),
        ('   ', '   ', False),
        (None, FAKE_ADMIN_PASSWORD, False),
        (FAKE_ADMIN_PASSWORD, 'incorrect', False),
        (FAKE_ADMIN_PASSWORD, FAKE_ADMIN_PASSWORD, True),
        (FAKE_ADMIN_PASSWORD, FAKE_ADMIN_PASSWORD + ' ', True),
    ):
        if serve.admin_password_ok(configured, supplied) != expected:
            fail(f'admin_password_ok inattendu pour config vide/incorrecte/attendue ({expected})')

    tmp, base = build_fixture()
    calls = []

    def fake_send(*args, **kwargs):
        calls.append(args)
        return {'success': True, 'provider': 'mock'}

    serve.send_email_server = fake_send
    httpd = start_server(base)
    port = httpd.server_address[1]
    try:
        if httpd.server_address[0] != '127.0.0.1':
            fail('socket de test non locale')

        probes = [
            '/backend/.env',
            '/JBF%20Public/../backend/.env',
            '/%2e%2e/backend/.env',
            '/%252e%252e/backend/.env',
            '/.git/HEAD',
            '/.env',
            '/JBF%20Public/.secret',
            '/backend/.env%00.html',
            '/JBF%20Public/%2e%2e/%2e%2e/backend/.env',
        ]
        for path in probes:
            status, payload, csp, frame = request(port, 'GET', path)
            if status != 403:
                fail(f'{path} -> {status}, attendu 403')
            if FAKE_SECRET.encode() in payload:
                fail(f'{path} a renvoyé le fichier factice')
            if 'frame-ancestors' not in csp or frame != 'DENY':
                fail('en-têtes anti-iframe absents')

        status, payload, _, _ = request(port, 'GET', '/JBF%20Public/index.html')
        if status != 200 or payload != b'hello-public':
            fail(f'asset public refusé ({status})')
        status, payload, _, _ = request(port, 'GET', '/assets/logo.txt')
        if status != 200 or payload != b'logo':
            fail('asset racine refusé')

        import io
        import contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            status, _, _, _ = request(port, 'POST', '/api/mail/send', {
                'to': 'fixture@example.test',
                'subject': f'Code {FAKE_OTP}',
                'html': f'<p>{FAKE_OTP}</p>'
            })
        if status != 403:
            fail(f'relais anonyme -> {status}')
        if calls:
            fail('le relais anonyme a appelé l\'envoi')
        if FAKE_OTP in buf.getvalue():
            fail('OTP factice journalisé sur refus anonyme')

        before = len(calls)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            status, payload, _, _ = request(port, 'POST', '/api/mail/send', {
                'to': 'fixture@example.test',
                'subject': f'Code {FAKE_OTP}',
                'html': f'<p>{FAKE_OTP}</p>'
            }, headers={'Origin': f'http://127.0.0.1:{port}', 'Sec-Fetch-Site': 'same-origin'})
        logged = buf.getvalue()
        if status != 403:
            fail(f'relais same-origin forgé -> {status}')
        if len(calls) != before:
            fail('le relais same-origin a quand même appelé l\'envoi')
        if FAKE_OTP in logged or FAKE_OTP.encode() in payload:
            fail('OTP factice présent dans la réponse ou les logs')

        status, _, _, _ = request(port, 'POST', '/api/mail/send', {
            'to': 'fixture@example.test',
            'subject': 'Code',
            'html': '<p>x</p>'
        }, headers={'Origin': 'https://evil.example', 'Sec-Fetch-Site': 'cross-site'})
        if status != 403:
            fail(f'origine externe -> {status}')

        serve.ADMIN_OFFICIAL_EMAIL = 'admin-fixture@example.test'
        serve.ADMIN_OFFICIAL_PASSWORD = ''
        status, _, _, _ = request(port, 'POST', '/api/admin/login', {
            'email': 'admin-fixture@example.test',
            'password': FAKE_ADMIN_PASSWORD
        })
        if status != 401:
            fail(f'mot de passe absent -> {status}')

        serve.ADMIN_OFFICIAL_PASSWORD = '   '
        status, _, _, _ = request(port, 'POST', '/api/admin/login', {
            'email': 'admin-fixture@example.test',
            'password': '   '
        })
        if status != 401:
            fail(f'mot de passe vide -> {status}')

        serve.ADMIN_OFFICIAL_PASSWORD = FAKE_ADMIN_PASSWORD
        status, _, _, _ = request(port, 'POST', '/api/admin/login', {
            'email': 'admin-fixture@example.test',
            'password': 'incorrect'
        })
        if status != 401:
            fail(f'mot de passe incorrect -> {status}')
        status, payload, _, _ = request(port, 'POST', '/api/admin/login', {
            'email': 'admin-fixture@example.test',
            'password': FAKE_ADMIN_PASSWORD
        })
        if status != 200 or b'"success": true' not in payload and b'"success":true' not in payload:
            fail(f'mot de passe correct -> {status}')
    finally:
        httpd.shutdown()
        tmp.cleanup()

    print('OK sécurité serve.py (fichiers, admin, OTP, relais)')


if __name__ == '__main__':
    main()
