#!/bin/bash

set -e

NAMESPACE="meteonow-dev"
SECRET_NAME="regcred"
DOCKER_CONFIG_PATH="$HOME/.docker/config.json"  # ➜ Modifie si ton fichier est ailleurs
CHART_PATH="."                  # ➜ Répertoire du chart Helm

echo "🔧 Création du namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "🔐 Création du secret imagePullSecret '$SECRET_NAME' à partir de '$DOCKER_CONFIG_PATH'..."
kubectl create secret generic "$SECRET_NAME" \
  --from-file=.dockerconfigjson="$DOCKER_CONFIG_PATH" \
  --type=kubernetes.io/dockerconfigjson \
  -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -


