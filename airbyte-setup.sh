#!/bin/bash
trap 'echo -e "\n❌ Une erreur s’est produite. Code de sortie: $?"; echo "💥 Dernière commande exécutée : $BASH_COMMAND"; read -p "Appuyez sur Entrée pour quitter..."' ERR

set -e
#!/bin/bash

# Chemin vers abctl (à adapter si besoin)
ABCTL="./abctl/abctl"

AIRBYTE_URL="http://localhost:8000"

# 1. Récupérer les credentials
CREDENTIALS=$($ABCTL local credentials 2>/dev/null || true)

ADMIN_EMAIL=$(echo "$CREDENTIALS" | grep -oP 'Email:\s+\K.*')
ADMIN_PASSWORD=$(echo "$CREDENTIALS" | grep -oP 'Password:\s+\K.*')
CLIENT_ID=$(echo "$CREDENTIALS" | grep -oP 'Client-Id:\s+\K.*')
CLIENT_SECRET=$(echo "$CREDENTIALS" | grep -oP 'Client-Secret:\s+\K.*')


ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | tr -d '\r' | xargs)
# Supprimer les codes couleurs ANSI (séquences d'échappement)
ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | xargs)
ADMIN_PASSWORD=$(echo "$ADMIN_PASSWORD" | tr -d '\r' | xargs)
# Supprimer les codes couleurs ANSI (séquences d'échappement)
ADMIN_PASSWORD=$(echo "$ADMIN_PASSWORD" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | xargs)
CLIENT_ID=$(echo "$CLIENT_ID" | tr -d '\r' | xargs)
# Supprimer les codes couleurs ANSI (séquences d'échappement)
CLIENT_ID=$(echo "$CLIENT_ID" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | xargs)
CLIENT_SECRET=$(echo "$CLIENT_SECRET" | tr -d '\r' | xargs)
# Supprimer les codes couleurs ANSI (séquences d'échappement)
CLIENT_SECRET=$(echo "$CLIENT_SECRET" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | xargs)
echo "📧 Email utilisé : $ADMIN_EMAIL"
echo "🔑 Password utilisé : $ADMIN_PASSWORD"

#WORKSPACE_ID="00000000-0000-0000-0000-000000000001"

# -----------------------------
# 🔐 Récupérer un token d'accès
# -----------------------------
echo "🔐 Authentification..."
AUTH_RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/applications/token" \
  -H "Content-Type: application/json" \
  -d '{"client_id": "'$CLIENT_ID'", "client_secret": "'$CLIENT_SECRET'"}')

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"access_token"[^"]*"[^"]*"' | sed -E 's/.*"access_token"[^"]*"([^"]*)".*/\1/')

if [ -z "$TOKEN" ]; then
  echo "❌ Impossible de récupérer un jeton d'accès"
  echo "📦 Réponse brute : $AUTH_RESPONSE"
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $TOKEN"
echo "✅ Jeton récupéré : $TOKEN"

#Recher du workspace

echo "🔍 Récupération du workspace..."
WORKSPACE_RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/workspaces/list" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{}')

WORKSPACE_ID=$(echo "$WORKSPACE_RESPONSE" | tr -d '\n' | awk -v RS='{' '
  /"workspaceId": ?"/ {
    match($0, /"workspaceId": ?"([^"]+)"/, arr)
    print arr[1]
    exit
  }
')

echo "🏷️ Workspace ID récupéré : $WORKSPACE_ID"

# -----------------------------
# 🔍 Recherche des définitions
# -----------------------------
echo "🔍 Recherche des IDs de connecteurs..."

SOURCE_DEFS=$(curl -s -X POST "$AIRBYTE_URL/api/v1/source_definitions/list" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" -d '{}')

SOURCE_DEF_ID=$(echo "$SOURCE_DEFS" | tr -d '\n' | awk -v RS='{' '
  /"name": ?"MongoDb"/ && /"sourceDefinitionId": ?"/ {
    match($0, /"sourceDefinitionId": ?"([^"]+)"/, arr)
    print arr[1]
    exit
  }
')


echo "🔗 ID Source MongoDB trouvé : $SOURCE_DEF_ID"

DEST_DEFS=$(curl -s -X POST "$AIRBYTE_URL/api/v1/destination_definitions/list" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" -d '{}')

DEST_DEF_ID=$(echo "$DEST_DEFS" | tr -d '\n' | awk -v RS='{' '
  /"name": ?"Postgres"/ && /"destinationDefinitionId": ?"/ {
    match($0, /"destinationDefinitionId": ?"([^"]+)"/, arr)
    print arr[1]
    exit
  }
')


echo "🔗 ID Destination PostgreSQL trouvé : $DEST_DEF_ID"


# -----------------------------
# 📦 Vérifier ou créer la source MongoDB
# -----------------------------
echo "🔍 Vérification de la source MongoDB..."
SOURCES=$(curl -s -X POST "$AIRBYTE_URL/api/v1/sources/list" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" \
  -d '{"workspaceId": "'$WORKSPACE_ID'"}')

MONGO_SOURCE_ID=$(echo "$SOURCES" | grep -o '"sourceId":\s*"[^"]*"' | sed -E 's/.*"sourceId":\s*"([^"]*)".*/\1/' | head -n1)

if [ -n "$MONGO_SOURCE_ID" ]; then
  echo "✅ Source MongoDB déjà existante : $MONGO_SOURCE_ID"
else
  echo "🔌 Création de la source MongoDB..."
  RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/sources/create" \
    -H "$AUTH_HEADER" -H "Content-Type: application/json" \
    -d '{
      "name": "MongoDB Source",
      "sourceDefinitionId": "'"$SOURCE_DEF_ID"'",
      "workspaceId": "'"$WORKSPACE_ID"'",
      "connectionConfiguration": {
        "database_config": {
          "cluster_type": "SELF_MANAGED_REPLICA_SET",
          "connection_string": "mongodb://host.docker.internal:27017",
          "database": "DataBase",
          "auth_source": "admin"
        }
      }
    }')

  echo "📦 Réponse création source MongoDB : $RESPONSE"
  MONGO_SOURCE_ID=$(echo "$RESPONSE" | grep -o '"sourceId"\s*:\s*"[^"]*"' | sed -E 's/.*"sourceId"\s*:\s*"([^"]*)".*/\1/')
  echo "✅ ID Source MongoDB : $MONGO_SOURCE_ID"
fi

# -----------------------------
# 📦 Vérifier ou créer la destination PostgreSQL
# -----------------------------
echo "🔍 Vérification de la destination PostgreSQL..."
DESTINATIONS=$(curl -s -X POST "$AIRBYTE_URL/api/v1/destinations/list" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" \
  -d '{"workspaceId": "'$WORKSPACE_ID'"}')

POSTGRES_DEST_ID=$(echo "$DESTINATIONS" | grep -o '"destinationId":\s*"[^"]*"' | sed -E 's/.*"destinationId":\s*"([^"]*)".*/\1/' | head -n1)

if [ -n "$POSTGRES_DEST_ID" ]; then
  echo "✅ Destination PostgreSQL déjà existante : $POSTGRES_DEST_ID"
else
  echo "📦 Création de la destination PostgreSQL..."
  RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/destinations/create" \
    -H "$AUTH_HEADER" -H "Content-Type: application/json" \
    -d '{
      "name": "Postgres Destination",
      "destinationDefinitionId": "'"$DEST_DEF_ID"'",
      "workspaceId": "'"$WORKSPACE_ID"'",
      "connectionConfiguration": {
        "host": "host.docker.internal",
        "port": 5432,
        "database": "db",
        "username": "sa",
        "password": "sa",
        "schema": "public",
        "ssl_mode": {
          "mode": "disable"
        }
      }
    }')

  echo "📦 Réponse création destination PostgreSQL : $RESPONSE"
  POSTGRES_DEST_ID=$(echo "$RESPONSE" | grep -o '"destinationId"\s*:\s*"[^"]*"' | sed -E 's/.*"destinationId"\s*:\s*"([^"]*)".*/\1/')
  echo "✅ ID Destination PostgreSQL : $POSTGRES_DEST_ID"
fi

# -----------------------------
# 📖 Découverte du schéma MongoDB avec log
# -----------------------------
echo "📖 Découverte du schéma MongoDB..."
CATALOG=$(curl -s -X POST "$AIRBYTE_URL/api/v1/sources/discover_schema" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" \
  -d '{"sourceId": "'$MONGO_SOURCE_ID'"}')

echo "📦 Résultat brut du catalog :"
echo "$CATALOG" | sed 's/{/\n{/g' | head -n 20  # aperçu partiel

if echo "$CATALOG" | grep -q '"catalog"'; then
  echo "✅ Schéma MongoDB découvert avec succès"
else
  echo "❌ Échec de la découverte du schéma MongoDB"
  echo "📦 Réponse brute : $CATALOG"
  read -p "👉 Appuyez sur Entrée pour continuer..."

  exit 1
fi

# -----------------------------
# 🔗 Créer la connexion complète
# -----------------------------
echo "🔗 Création de la connexion entre MongoDB et PostgreSQL..."
RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/connections/create" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "sourceId": "$MONGO_SOURCE_ID",
  "destinationId": "$POSTGRES_DEST_ID",
  "status": "active",
  "syncCatalog": $CATALOG
}
EOF
)


if echo "$RESPONSE" | grep -q 'connectionId'; then
  echo "✅ Connexion MongoDB -> PostgreSQL créée avec succès !"
else
  echo "❌ Erreur lors de la création de la connexion."
  echo "📦 Réponse brute : $RESPONSE"
  exit 1
fi

# -----------------------------
# 🚀 Lancer la première synchronisation
# -----------------------------
CONNECTION_ID=$(echo "$RESPONSE" | grep -o '"connectionId"\s*:\s*"[^"]*"' | sed -E 's/.*"connectionId"\s*:\s*"([^"]*)".*/\1/')

echo "🚀 Lancement de la première synchronisation..."
RESPONSE=$(curl -s -X POST "$AIRBYTE_URL/api/v1/connections/sync" \
  -H "$AUTH_HEADER" -H "Content-Type: application/json" \
  -d '{"connectionId": "'$CONNECTION_ID'"}')

echo "✅ Synchronisation lancée !"
exit 0
