#!/usr/bin/env python3
"""
Serveur HTTPS local simplifié pour l'application TimeSheet Flutter Web
Version alternative sans OpenSSL
"""

import os
import http.server
import socketserver
from pathlib import Path
import ssl
import tempfile
import subprocess
import sys

# Configuration
PORT = 8443
WEB_DIR = "build/web"

def create_simple_cert():
    """Crée un certificat SSL simple ou utilise une alternative"""
    cert_file = "localhost.crt"
    key_file = "localhost.key"
    
    # Essayer de trouver OpenSSL dans différents emplacements
    openssl_paths = [
        "openssl",
        "C:\\Program Files\\Git\\usr\\bin\\openssl.exe",
        "C:\\Program Files\\Git\\bin\\openssl.exe",
        "C:\\msys64\\usr\\bin\\openssl.exe"
    ]
    
    openssl_found = None
    for path in openssl_paths:
        try:
            result = subprocess.run([path, "version"], capture_output=True, text=True)
            if result.returncode == 0:
                openssl_found = path
                break
        except:
            continue
    
    if openssl_found:
        print(f"🔐 OpenSSL trouvé : {openssl_found}")
        print("🔐 Création du certificat SSL auto-signé...")
        
        # Créer le certificat avec OpenSSL
        cmd = [
            openssl_found,
            "req", "-x509", "-newkey", "rsa:4096",
            "-keyout", key_file, "-out", cert_file,
            "-days", "365", "-nodes",
            "-subj", "/C=FR/ST=IDF/L=Paris/O=TimeSheet/CN=localhost"
        ]
        
        try:
            subprocess.run(cmd, check=True)
            if os.path.exists(cert_file) and os.path.exists(key_file):
                print("✅ Certificat SSL créé avec succès !")
                return cert_file, key_file
        except subprocess.CalledProcessError:
            print("❌ Erreur lors de la création du certificat SSL")
    
    # Alternative : créer des certificats temporaires ou utiliser HTTP avec headers
    print("⚠️  OpenSSL non trouvé, utilisation du mode HTTP avec headers de sécurité")
    return None, None

def serve_secure():
    """Démarre le serveur sécurisé (HTTPS ou HTTP avec headers)"""
    if not os.path.exists(WEB_DIR):
        print(f"❌ Dossier {WEB_DIR} non trouvé !")
        print("💡 Exécutez d'abord : flutter build web")
        return
    
    # Essayer de créer des certificats SSL
    cert_file, key_file = create_simple_cert()
    
    if cert_file and key_file and os.path.exists(cert_file) and os.path.exists(key_file):
        # Mode HTTPS avec certificat SSL
        serve_https(cert_file, key_file)
    else:
        # Mode HTTP avec headers de sécurité (alternative)
        serve_http_secure()

def serve_https(cert_file, key_file):
    """Démarre le serveur HTTPS"""
    try:
        # Configuration du serveur HTTPS
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(cert_file, key_file)
        
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
            print(f"🔐 Certificat SSL : {cert_file}")
            print(f"🔑 Clé privée : {key_file}")
            print("\n⚠️  IMPORTANT :")
            print("   1. Acceptez le certificat auto-signé dans votre navigateur")
            print("   2. La caméra devrait maintenant fonctionner !")
            print("   3. Appuyez sur Ctrl+C pour arrêter le serveur")
            
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print("\n🛑 Serveur arrêté")
                
    except Exception as e:
        print(f"❌ Erreur serveur HTTPS : {e}")
        print("🔄 Basculement vers le mode HTTP sécurisé...")
        serve_http_secure()

def serve_http_secure():
    """Démarre le serveur HTTP avec headers de sécurité"""
    class SecureHTTPHandler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=WEB_DIR, **kwargs)
        
        def end_headers(self):
            # Headers pour la sécurité et la caméra
            self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
            self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
            self.send_header('Permissions-Policy', 'camera=*, microphone=*')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('X-Frame-Options', 'DENY')
            super().end_headers()
    
    try:
        with socketserver.TCPServer(("", PORT), SecureHTTPHandler) as httpd:
            print(f"🌐 Serveur HTTP sécurisé démarré sur : http://localhost:{PORT}")
            print(f"📁 Dossier servi : {os.path.abspath(WEB_DIR)}")
            print("\n⚠️  MODE ALTERNATIF :")
            print("   1. Serveur HTTP avec headers de sécurité")
            print("   2. La caméra peut ne pas fonctionner sur certains navigateurs")
            print("   3. Pour une caméra 100% fonctionnelle, installez OpenSSL")
            print("   4. Appuyez sur Ctrl+C pour arrêter le serveur")
            
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print("\n🛑 Serveur arrêté")
                
    except Exception as e:
        print(f"❌ Erreur serveur HTTP : {e}")

if __name__ == "__main__":
    print("🚀 Démarrage du serveur sécurisé pour TimeSheet App...")
    print("📱 Objectif : Rendre la caméra accessible sur le web")
    print("=" * 60)
    
    serve_secure()
