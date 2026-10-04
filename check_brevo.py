import urllib.request
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
BREVO_KEY = os.environ.get('BREVO_API_KEY') or _env.get('BREVO_API_KEY', '')

def check_brevo():
    out = {}
    
    # 1. Senders
    try:
        req = urllib.request.Request('https://api.brevo.com/v3/senders', headers={'api-key': BREVO_KEY, 'accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=5) as resp:
            out['senders'] = json.loads(resp.read().decode())
    except Exception as e:
        out['senders_error'] = str(e)
        
    # 2. Account info
    try:
        req = urllib.request.Request('https://api.brevo.com/v3/account', headers={'api-key': BREVO_KEY, 'accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=5) as resp:
            out['account'] = json.loads(resp.read().decode())
    except Exception as e:
        out['account_error'] = str(e)

    # 3. Transactional events
    try:
        req = urllib.request.Request('https://api.brevo.com/v3/smtp/statistics/events?email=dankande3@gmail.com', headers={'api-key': BREVO_KEY, 'accept': 'application/json'})
        with urllib.request.urlopen(req, timeout=5) as resp:
            out['events'] = json.loads(resp.read().decode())
    except Exception as e:
        out['events_error'] = str(e)

    with open('brevo_diag.json', 'w', encoding='utf-8') as f:
        json.dump(out, f, indent=2)

if __name__ == '__main__':
    check_brevo()
