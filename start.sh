#!/bin/bash
trap 'echo -e "\n❌ Une erreur s’est produite. Appuyez sur Entrée pour quitter..."; read' ERR
set -e

ABCTL="./abctl/abctl"

# 1. Vérifier la présence du binaire
if [ ! -f "$ABCTL" ]; then
  echo "❌ abctl introuvable dans ./abctl/"
  exit 1
fi

# 2. Lancer install (fait install + start si besoin)
echo "🚀 Lancement de Airbyte avec abctl local install..."
if ! $ABCTL local install; then
  echo "⚠️ Airbyte ne s'est pas lancé, tentative de redémarrage du container Docker..."

  # Redémarrer le container si existant mais stoppé
  docker start airbyte-abctl-control-plane 2>/dev/null || echo "🧱 Aucun container existant nommé 'airbyte-abctl-control-plane' trouvé."

  # Attendre un peu que le container démarre
  sleep 5

  echo "🔁 Nouvelle tentative : abctl local install..."
  $ABCTL local install
fi


# 3. Attendre qu'Airbyte soit prêt
echo "🕒 Attente que Airbyte soit accessible sur localhost:8000..."
until curl -s http://localhost:8000 >/dev/null; do
  sleep 2
done
echo "✅ Airbyte est prêt !"

# 4. Récupérer les credentials
CREDENTIALS=$($ABCTL local credentials 2>/dev/null || true)

ADMIN_EMAIL=$(echo "$CREDENTIALS" | grep -oP 'Email:\s+\K.*')
ADMIN_PASSWORD=$(echo "$CREDENTIALS" | grep -oP 'Password:\s+\K.*')

echo "📧 Email récupéré : $ADMIN_EMAIL"
echo "🔑 Mot de passe récupéré : $ADMIN_PASSWORD"

echo "Création du réseau"
#docker network rm app-network || true
docker network create \
  --driver bridge \
  --subnet 172.28.0.0/16 \
  app-network || true

# 5. Lancer docker-compose
echo "🐳 Démarrage des conteneurs..."
docker-compose up -d --build --wait || true
#echo "📧 DEBUG HEX : $(echo -n "$ADMIN_EMAIL" | xxd)"
ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | tr -d '\r' | xargs)
# Supprimer les codes couleurs ANSI (séquences d'échappement)
ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | xargs)
echo "Mettre airbyte dans le même réseau"
docker network connect app-network airbyte-abctl-control-plane || true

echo "⏳ Waiting for MongoDB to be healthy..."
until [ "$(docker inspect --format='{{json .State.Health.Status}}' mongodb)" == "\"healthy\"" ]; do
  sleep 1
done

echo "✅ MongoDB is healthy, starting replica set init..."

docker exec mongodb mongosh --eval '
  if (!rs.status().ok) {
    print("🔧 Initiating replica set...");
    rs.initiate();
    sleep(5000);
  }

  const cfg = rs.conf();
  cfg.members[0].host = "mongodb:27017";
  rs.reconfig(cfg, { force: true });
  print("✅ Replica set host updated to mongodb:27017");
'
if [[ "$ADMIN_EMAIL" != "[not set]" ]]; then
  echo "✅ Airbyte est déjà initialisé avec l'email : $ADMIN_EMAIL"
  echo "⛔️ Arrêt du script pour éviter une reconfiguration."
  read -p "💡 Appuyez sur Entrée pour quitter..."

  exit 0
fi

echo "⏳ Attente que l'email admin soit configuré sur Airbyte..."

# Boucle jusqu'à ce que l'email ne soit plus '[not set]'
while true; do
  CREDENTIALS=$($ABCTL local credentials 2>/dev/null || true)
  ADMIN_EMAIL=$(echo "$CREDENTIALS" | grep -oP 'Email:\s+\K.*')
  ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | xargs)  # Trim des espaces éventuels
  ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n' | xargs)
  echo "📧 Email détecté : '$ADMIN_EMAIL'"

  if [[ "$ADMIN_EMAIL" != "[not set]" && -n "$ADMIN_EMAIL" ]]; then
    echo "✅ Email configuré : $ADMIN_EMAIL"
    break
  fi

  sleep 3
done
# 6. Lancer la config Airbyte si première initialisation
echo "⚙️ Configuration initiale d’Airbyte..."
bash airbyte-setup.sh




# 7. Pause finale
echo ""
read -p "💡 Appuyez sur Entrée pour quitter..."
