import os
import time
import requests

MB_URL = os.environ.get("MB_URL", "http://metabase:3000")
MB_USER = os.environ.get("MB_USER", "admin@admin.com")
MB_PASSWORD = os.environ.get("MB_PASSWORD", "Admin_1234!")

PG_NAME = "PostgreSQL-Auto"
PG_HOST = os.environ.get("METABASE_DB_HOST", "postgres")
PG_PORT = int(os.environ.get("METABASE_DB_PORT", 5432))
PG_DB = os.environ.get("METABASE_DB_NAME", "db")
PG_USER = os.environ.get("METABASE_DB_USER", "sa")
PG_PASS = os.environ.get("METABASE_DB_PASS", "sa")

def wait_for_metabase():
    print("⏳ Attente du démarrage de Metabase...")
    while True:
        try:
            res = requests.get(f"{MB_URL}/api/health")
            if res.status_code == 200:
                print("✅ Metabase est prêt.")
                break
        except requests.exceptions.RequestException:
            pass
        time.sleep(2)

def is_metabase_already_setup():
    res = requests.get(f"{MB_URL}/api/session/properties")
    return res.json().get("setup-token") is None

def setup_admin_user():
    print("🛠️ Création de l'utilisateur admin...")
    res_token = requests.get(f"{MB_URL}/api/session/properties")
    token = res_token.json().get("setup-token")
    if not token:
        print("⚠️ Metabase déjà initialisé.")
        return

    res = requests.post(f"{MB_URL}/api/setup", json={
        "token": token,
        "user": {
            "email": MB_USER,
            "password": MB_PASSWORD,
            "first_name": "Admin",
            "last_name": "User"
        },
        "prefs": {
            "site_name": "Auto-Metabase",
            "site_locale": "fr"
        },
        "database": None
    })

    if res.status_code != 200:
        print(f"❌ Erreur création admin: {res.text}")
    else:
        print("✅ Utilisateur admin créé.")

def login():
    print(f"🔐 Connexion à Metabase avec {MB_USER}")
    res = requests.post(f"{MB_URL}/api/session", json={
        "username": MB_USER,
        "password": MB_PASSWORD
    })
    res.raise_for_status()
    session_id = res.json()['id']
    print("✅ Connecté.")
    return {"X-Metabase-Session": session_id}

def check_postgres_exists(headers):
    res = requests.get(f"{MB_URL}/api/database", headers=headers)
    data = res.json()
    databases = data.get("data", [])  # ← récupère la vraie liste

    for db in databases:
        if db["name"] == PG_NAME:
            print(f"ℹ️ PostgreSQL déjà existant (id={db['id']})")
            return db["id"]
    return None


def add_postgres_db(headers):
    print("➕ Ajout de PostgreSQL comme source de données...")
    res = requests.post(f"{MB_URL}/api/database", headers=headers, json={
        "name": PG_NAME,
        "engine": "postgres",
        "details": {
            "host": PG_HOST,
            "port": PG_PORT,
            "dbname": PG_DB,
            "user": PG_USER,
            "password": PG_PASS,
            "ssl": False
        },
        "is_full_sync": True,
        "is_on_demand": False
    })
    res.raise_for_status()
    db_id = res.json()['id']
    print(f"✅ PostgreSQL ajouté (id: {db_id})")
    return db_id

def trigger_sync(headers, db_id):
    print("🔄 Lancement du scan des tables...")
    res = requests.post(f"{MB_URL}/api/database/{db_id}/sync_schema", headers=headers)
    res.raise_for_status()
    print("✅ Scan lancé.")

def main():
    wait_for_metabase()

    if not is_metabase_already_setup():
        setup_admin_user()

    headers = login()

    db_id = check_postgres_exists(headers)
    if not db_id:
        db_id = add_postgres_db(headers)

    trigger_sync(headers, db_id)

if __name__ == "__main__":
    main()
