#!/usr/bin/env python3
"""
Serveur HTTPS local pour l'application TimeSheet Flutter Web
Permet l'accès à la caméra en développement local
"""

import os
import ssl
import http.server
import socketserver
from pathlib import Path

# Configuration
PORT = 8443
CERT_FILE = "localhost.crt"
KEY_FILE = "localhost.key"
WEB_DIR = "build/web"

def create_self_signed_cert():
    """Crée un certificat SSL auto-signé pour localhost"""
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("🔐 Création du certificat SSL auto-signé...")
        
        # Commande OpenSSL pour créer le certificat
        os.system(f'openssl req -x509 -newkey rsa:4096 -keyout {KEY_FILE} -out {CERT_FILE} -days 365 -nodes -subj "/C=FR/ST=IDF/L=Paris/O=TimeSheet/CN=localhost"')
        
        if os.path.exists(CERT_FILE) and os.path.exists(KEY_FILE):
            print("✅ Certificat SSL créé avec succès !")
        else:
            print("❌ Erreur lors de la création du certificat SSL")
            return False
    return True

def serve_https():
    """Démarre le serveur HTTPS"""
    if not os.path.exists(WEB_DIR):
        print(f"❌ Dossier {WEB_DIR} non trouvé !")
        print("💡 Exécutez d'abord : flutter build web")
        return
    
    # Vérifier/créer le certificat SSL
    if not create_self_signed_cert():
        return
    
    # Configuration du serveur HTTPS
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(CERT_FILE, KEY_FILE)
    
    # Handler pour servir les fichiers statiques
    class HTTPSHandler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=WEB_DIR, **kwargs)
        
        def end_headers(self):
            # Headers pour la sécurité et la caméra
            self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
            self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
            self.send_header('Permissions-Policy', 'camera=*, microphone=*')
            super().end_headers()
    
    # Créer le serveur
    with socketserver.TCPServer(("", PORT), HTTPSHandler) as httpd:
        # Wrapper SSL
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
        
        print(f"🚀 Serveur HTTPS démarré sur : https://localhost:{PORT}")
        print(f"📁 Dossier servi : {os.path.abspath(WEB_DIR)}")
        print(f"🔐 Certificat SSL : {CERT_FILE}")
        print(f"🔑 Clé privée : {KEY_FILE}")
        print("\n⚠️  IMPORTANT :")
        print("   1. Acceptez le certificat auto-signé dans votre navigateur")
        print("   2. La caméra devrait maintenant fonctionner !")
        print("   3. Appuyez sur Ctrl+C pour arrêter le serveur")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Serveur arrêté")

if __name__ == "__main__":
    serve_https()
