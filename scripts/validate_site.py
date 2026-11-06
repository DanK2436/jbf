#!/usr/bin/env python3
"""Contrôles statiques du site JBF : mouvement, secrets client, viewport."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
errors = []


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8")


main_css = read("JBF Public/css/main.css")
client_css = read("JBF Client/css/client.css")
hero_js = read("JBF Public/js/hero-slideshow.js")
mail_js = read("supabase/mail-service.js")

if "prefers-reduced-motion: reduce" not in main_css:
    errors.append("main.css ne contient pas prefers-reduced-motion")
if "prefers-reduced-motion: reduce" not in client_css:
    errors.append("client.css ne contient pas prefers-reduced-motion")
if ".ticker-wrap" not in main_css or "animation: none" not in main_css:
    errors.append("le ticker infini n'est pas désactivé en mouvement réduit")
if "scroll-behavior: auto" not in main_css or "scroll-behavior: auto" not in client_css:
    errors.append("le scroll fluide n'est pas neutralisé")
if "scroll-behavior: smooth" not in main_css.split("prefers-reduced-motion: no-preference")[-1][:400]:
    errors.append("le scroll fluide n'est pas réservé à no-preference dans main.css")

for needle in ("prefers-reduced-motion", "addEventListener('change'", "shouldRunTimer", "heroPause", "stopTimer"):
    if needle not in hero_js:
        errors.append(f"hero-slideshow.js ne contient pas {needle}")
if "DOMContentLoaded" in hero_js:
    block = hero_js.split("DOMContentLoaded", 1)[1][:1200]
    if "startTimerIfAllowed()" not in block or "prefersReducedMotion()" not in block:
        errors.append("le diaporama démarre sans tester le mouvement réduit")

if re.search(r"xkeysib-[A-Za-z0-9]{8,}", mail_js) or "DEFAULT_BREVO_KEY" in mail_js or "DEFAULT_RESEND_KEY" in mail_js:
    errors.append("une clé fournisseur reste embarquée dans mail-service.js")
if "config_cles_api" in mail_js:
    errors.append("mail-service.js lit encore les secrets config_cles_api")

for html in (ROOT / "JBF Public").rglob("*.html"):
    text = html.read_text(encoding="utf-8")
    if "viewport" not in text:
        errors.append(f"viewport manquant : {html.relative_to(ROOT)}")

client_pages = list((ROOT / "JBF Client").rglob("*.html"))
for html in client_pages:
    text = html.read_text(encoding="utf-8")
    if "viewport" not in text:
        errors.append(f"viewport manquant : {html.relative_to(ROOT)}")

if errors:
    print("ÉCHEC validation site")
    for err in errors:
        print("-", err)
    sys.exit(1)

print(f"OK validation site ({len(list((ROOT / 'JBF Public').rglob('*.html')))} pages publiques, {len(client_pages)} pages client)")
