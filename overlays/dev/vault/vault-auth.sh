#!/bin/bash

# === CONFIG ===
SA_NAME="vault-auth"
SA_NAMESPACE="vault-prod"

echo "📌 Using ServiceAccount: $SA_NAME in namespace: $SA_NAMESPACE"

# === Get JWT token from the ServiceAccount ===
echo "🔐 Generating token from ServiceAccount..."
SA_JWT_TOKEN=$(kubectl create token "$SA_NAME" -n "$SA_NAMESPACE")

if [ -z "$SA_JWT_TOKEN" ]; then
  echo "❌ Failed to get token for ServiceAccount $SA_NAME"
  exit 1
fi

# === Get Kubernetes API CA certificate ===
echo "📄 Retrieving cluster CA certificate..."
SA_CA_CRT=$(kubectl get configmap -n kube-system kube-root-ca.crt -o jsonpath="{.data['ca\.crt']}")

if [ -z "$SA_CA_CRT" ]; then
  echo "❌ Failed to get cluster CA certificate"
  exit 1
fi

# === Get Kubernetes API server address ===
echo "🌐 Detecting Kubernetes API server address..."
K8S_HOST=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

if [ -z "$K8S_HOST" ]; then
  echo "❌ Failed to detect Kubernetes API server address"
  exit 1
fi

# === Write config into Vault ===
echo "🚀 Configuring Vault auth method 'kubernetes'..."
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert="$SA_CA_CRT"

if [ $? -eq 0 ]; then
  echo "✅ Vault Kubernetes auth method configured successfully!"
else
  echo "❌ Failed to configure Vault auth method"
  exit 1
fi
