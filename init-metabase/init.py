import os
import time
import requests

mb_url = os.getenv("MB_URL")
mb_user = os.getenv("MB_USER")
mb_password = os.getenv("MB_PASSWORD")
mongo_uri = os.getenv("MONGO_URI")
mongo_db = os.getenv("MONGO_DB")

print("⏳ Attente du démarrage de Metabase...")
time.sleep(15)

# Vérifie si Metabase est déjà configuré
status = requests.get(f"{mb_url}/api/session/properties")
if not status.ok:
    print("❌ Metabase inaccessible.")
    exit()

if status.json().get("setup-token"):
    print("🛠️ Création de l'utilisateur admin...")
    setup_resp = requests.post(f"{mb_url}/api/setup", json={
        "prefs": {
            "site_name": "Auto Metabase",
            "allow_tracking": False
        },
        "user": {
            "email": mb_user,
            "password": mb_password,
            "first_name": "Admin",
            "last_name": "Auto"
        },
        "database": None
    })
    if setup_resp.status_code != 200:
        print("❌ Erreur création admin:", setup_resp.text)
        exit()
    session_id = setup_resp.json()["id"]
else:
    print("🔐 Connexion à Metabase...")
    resp = requests.post(f"{mb_url}/api/session", json={
        "username": mb_user,
        "password": mb_password
    })
    if resp.status_code != 200:
        print("❌ Erreur de connexion:", resp.text)
        exit()
    session_id = resp.json()["id"]

headers = {"X-Metabase-Session": session_id}

print("🧩 Ajout de la base MongoDB...")
db_payload = {
    "name": "MongoDB Auto",
    "engine": "mongo",
    "details": {
        "host": mongo_uri,
        "use_srv": True,
        "ssl": True,
        "dbname": mongo_db,
        "auth_source": "admin"
    },
    "is_full_sync": True,
    "is_on_demand": False
}

resp = requests.post(f"{mb_url}/api/database", json=db_payload, headers=headers)
if resp.status_code == 200:
    print("✅ Base MongoDB connectée et en cours d’analyse.")
else:
    print("❌ Erreur ajout base MongoDB:", resp.text)
