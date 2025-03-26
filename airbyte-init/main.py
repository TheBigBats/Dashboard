# import os
# import time
# import requests
#
# AIRBYTE_URL = os.getenv("AIRBYTE_URL", "http://localhost:8001")
#
# headers = {
#     "accept": "application/json",
#     "Content-Type": "application/json"
# }
#
# def wait_for_airbyte():
print("⏳ Attente du démarrage d'Airbyte...")
#     for _ in range(20):
#         try:
#             res = requests.get(f"{AIRBYTE_URL}/health")
#             if res.ok:
#                 print("✅ Airbyte prêt.")
#                 return
#         except:
#             pass
#         time.sleep(5)
#     raise Exception("❌ Airbyte ne démarre pas.")
#
# def create_source_mongo():
#     print("🔌 Création de la source MongoDB...")
#     payload = {
#         "name": "MongoDB Source",
#         "sourceDefinitionId": "435bb9a5-7887-4809-aa58-28c27df0d7ad",  # Mongo
#         "workspaceId": workspace_id,
#         "connectionConfiguration": {
#             "host": os.getenv("MONGO_HOST", "mongodb"),
#             "port": int(os.getenv("MONGO_PORT", "27017")),
#             "database": "default",
#             "auth_source": "admin",
#             "tls": False
#         }
#     }
#     r = requests.post(f"{AIRBYTE_URL}/v1/sources/create", json=payload)
#     return r.json()["sourceId"]
#
# def create_destination_postgres():
#     print("💾 Création de la destination PostgreSQL...")
#     payload = {
#         "name": "Postgres Destination",
#         "destinationDefinitionId": "25c5221d-dce2-4163-ade9-739ef790f503",  # PostgreSQL
#         "workspaceId": workspace_id,
#         "connectionConfiguration": {
#             "host": os.getenv("POSTGRES_HOST", "postgres"),
#             "port": int(os.getenv("POSTGRES_PORT", "5432")),
#             "username": os.getenv("POSTGRES_USER", "sa"),
#             "password": os.getenv("POSTGRES_PASSWORD", "sa"),
#             "database": os.getenv("POSTGRES_DB", "db"),
#             "schema": "public",
#             "ssl": False
#         }
#     }
#     r = requests.post(f"{AIRBYTE_URL}/v1/destinations/create", json=payload)
#     return r.json()["destinationId"]
#
# def create_connection(source_id, destination_id):
#     print("🔁 Création de la connexion MongoDB → PostgreSQL...")
#     # Get catalog
#     catalog = requests.post(f"{AIRBYTE_URL}/v1/sources/discover_schema", json={"sourceId": source_id}).json()
#
#     payload = {
#         "sourceId": source_id,
#         "destinationId": destination_id,
#         "name": "Mongo_to_Postgres",
#         "syncCatalog": catalog["catalog"],
#         "status": "active",
#         "namespaceDefinition": "destination",
#         "namespaceFormat": "${SOURCE_NAMESPACE}",
#         "destinationSchema": "public",
#         "scheduleType": "manual",  # à changer en basic pour sync auto
#         "geography": "auto"
#     }
#
#     r = requests.post(f"{AIRBYTE_URL}/v1/connections/create", json=payload)
#     print("✅ Connexion créée avec ID:", r.json().get("connectionId"))
#
# # === Lancement
# wait_for_airbyte()
#
# workspace_id = requests.post(f"{AIRBYTE_URL}/v1/workspaces/list", json={}).json()["workspaces"][0]["workspaceId"]
# source_id = create_source_mongo()
# dest_id = create_destination_postgres()
# create_connection(source_id, dest_id)
