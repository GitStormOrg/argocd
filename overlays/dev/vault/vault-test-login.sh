#!/bin/bash

# === CONFIGURATION ===
NAMESPACE="meteonow-dev"
APP_LABEL="app.kubernetes.io/name=meteonow"
VAULT_ROLE="meteonow"
SA_NAME_EXPECTED="meteonow-dev-sa"
VAULT_AUTH_PATH="auth/kubernetes"  # change si custom path comme "auth/k8s"

echo "🔍 Vérification de la cohérence Vault/Kubernetes pour l’auth K8s"
echo "Namespace: $NAMESPACE"
echo "Vault Role: $VAULT_ROLE"
echo "ServiceAccount attendu: $SA_NAME_EXPECTED"
echo "Vault Auth Path: $VAULT_AUTH_PATH"
echo "----------------------------------------"

# === 1. Vérifier le ServiceAccount utilisé par le pod ===
POD_NAME=$(kubectl get pod -n "$NAMESPACE" -l "$APP_LABEL" -o jsonpath="{.items[0].metadata.name}")
SA_USED=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath="{.spec.serviceAccountName}")

echo "📦 Pod détecté: $POD_NAME"
echo "🔐 ServiceAccount utilisé par le pod: $SA_USED"

if [[ "$SA_USED" != "$SA_NAME_EXPECTED" ]]; then
  echo "❌ Le pod utilise un SA différent de celui attendu ($SA_NAME_EXPECTED)"
else
  echo "✅ Le ServiceAccount est correct"
fi

# === 2. Lire les détails du rôle Vault ===
echo "📥 Lecture du rôle Vault: $VAULT_ROLE"
vault read "${VAULT_AUTH_PATH}/role/${VAULT_ROLE}" > /tmp/vault_role_check 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "❌ Le rôle Vault '${VAULT_ROLE}' n'existe pas dans '${VAULT_AUTH_PATH}'"
  exit 1
fi

BOUND_SA=$(grep bound_service_account_names /tmp/vault_role_check | awk -F']' '{print $1}' | awk -F'[' '{print $2}')
BOUND_NS=$(grep bound_service_account_namespaces /tmp/vault_role_check | awk -F']' '{print $1}' | awk -F'[' '{print $2}')

echo "🔍 SA(s) autorisé(s) dans Vault : $BOUND_SA"
echo "🔍 Namespace(s) autorisé(s) dans Vault : $BOUND_NS"

if [[ "$BOUND_SA" != *"$SA_USED"* || "$BOUND_NS" != *"$NAMESPACE"* ]]; then
  echo "❌ Le rôle Vault ne correspond pas au SA ou namespace utilisés par le pod"
else
  echo "✅ Le rôle Vault est correctement configuré"
fi

# === 3. Vérifier la policy associée (optionnel mais utile)
echo "📄 Vérification de la policy associée ($VAULT_ROLE)"
vault policy read "$VAULT_ROLE" >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "✅ La policy '$VAULT_ROLE' existe"
else
  echo "❌ La policy '$VAULT_ROLE' est manquante"
fi

# === 4. Vérification de la config auth/kubernetes ===
echo "⚙️  Vérification de la config de l’auth method Kubernetes"
vault read "$VAULT_AUTH_PATH/config" > /tmp/vault_k8s_config 2>/dev/null

if [[ $? -ne 0 ]]; then
  echo "❌ Impossible de lire la config de $VAULT_AUTH_PATH"
  exit 1
fi

grep -q "token_reviewer_jwt_set.*true" /tmp/vault_k8s_config && \
  echo "✅ token_reviewer_jwt correctement configuré" || \
  echo "❌ token_reviewer_jwt est manquant ou invalide"

grep -q "kubernetes_ca_cert.*BEGIN CERTIFICATE" /tmp/vault_k8s_config && \
  echo "✅ kubernetes_ca_cert présent" || \
  echo "❌ kubernetes_ca_cert est manquant"

grep -q "kubernetes_host.*https" /tmp/vault_k8s_config && \
  echo "✅ kubernetes_host correctement défini" || \
  echo "❌ kubernetes_host est invalide"

echo "----------------------------------------"
echo "🎯 Vérification terminée"
