import json
import urllib.request
import urllib.error

import os

def _load_env():
    env = {}
    p = os.path.join(os.path.dirname(__file__), 'backend', '.env')
    if os.path.exists(p):
        with open(p, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env[k.strip()] = v.strip().strip('"').strip("'")
    return env

_env = _load_env()
BREVO_API_KEY = os.environ.get('BREVO_API_KEY') or _env.get('BREVO_API_KEY', '')
RESEND_API_KEY = os.environ.get('RESEND_API_KEY') or _env.get('RESEND_API_KEY', '')

def test_resend():
    url = "https://api.resend.com/emails"
    headers = {
        "Authorization": f"Bearer {RESEND_API_KEY}",
        "Content-Type": "application/json",
        "User-Agent": "JBF-Backend/1.0"
    }
    payload = json.dumps({
        "from": "JBF SERVICES <onboarding@resend.dev>",
        "to": ["delivered@resend.dev"],
        "subject": "Test Diagnostic JBF Resend",
        "html": "<p>Test Resend</p>"
    }).encode("utf-8")
    
    req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print("RESEND SUCCESS:", resp.status, resp.read().decode("utf-8"))
            return True
    except urllib.error.HTTPError as e:
        print("RESEND HTTP ERROR:", e.code, e.read().decode("utf-8"))
    except Exception as e:
        print("RESEND EXCEPTION:", e)
    return False

def test_brevo():
    url = "https://api.brevo.com/v3/smtp/email"
    headers = {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "JBF-Backend/1.0"
    }
    payload = json.dumps({
        "sender": {"name": "JBF SERVICES", "email": "contact@jbf-services.cd"},
        "to": [{"email": "delivered@resend.dev"}],
        "subject": "Test Diagnostic JBF Brevo",
        "htmlContent": "<p>Test Brevo</p>"
    }).encode("utf-8")
    
    req = urllib.request.Request(url, data=payload, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print("BREVO SUCCESS:", resp.status, resp.read().decode("utf-8"))
            return True
    except urllib.error.HTTPError as e:
        print("BREVO HTTP ERROR:", e.code, e.read().decode("utf-8"))
    except Exception as e:
        print("BREVO EXCEPTION:", e)
    return False

if __name__ == "__main__":
    print("Testing APIs...")
    r = test_resend()
    b = test_brevo()
    print(f"Summary: Resend={r}, Brevo={b}")
