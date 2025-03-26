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

ADMIN_EMAIL=$(echo "$CREDENTIALS" | grep -i "Email:" | sed 's/.*Email:[[:space:]]*//')
ADMIN_PASSWORD=$(echo "$CREDENTIALS" | grep -i "Password:" | sed 's/.*Password:[[:space:]]*//')

echo "📧 Email récupéré : $ADMIN_EMAIL"
echo "🔑 Mot de passe récupéré : $ADMIN_PASSWORD"

# 5. Lancer docker-compose
echo "🐳 Démarrage des conteneurs..."
docker-compose up -d --build --wait

# 6. Lancer la config Airbyte si première initialisation
if [ -z "$ADMIN_EMAIL" ]; then
  echo "⚙️ Configuration initiale d’Airbyte..."
  bash airbyte-setup.sh
else
  echo "✅ Airbyte déjà initialisé."
fi

# 7. Pause finale
echo ""
read -p "💡 Appuyez sur Entrée pour quitter..."
