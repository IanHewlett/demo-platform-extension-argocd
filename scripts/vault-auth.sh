#!/usr/bin/env bash
vault_namespace="admin"
role_name="di-admin-kubernetes-role"
policy_name="di-admin-kubernetes-policy"
auth_path="$CLUSTER_NAME"

vault policy write -namespace="$vault_namespace" "$policy_name" - <<EOF
path "test/*" {
  capabilities = ["read"]
}
path "avp/*" {
  capabilities = ["read"]
}
path "secret/*" {
  capabilities = ["read"]
}
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
EOF

vault read -namespace="$vault_namespace" auth/"$auth_path"/config 1> /dev/null || \
  vault auth enable -namespace="$vault_namespace" -path="$auth_path" kubernetes

vault write -namespace="$vault_namespace" auth/"$auth_path"/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

vault write -namespace="$vault_namespace" auth/"$auth_path"/role/"$role_name" \
  bound_service_account_names="*" \
  bound_service_account_namespaces='kube-system,istio-system,cert-manager,argocd' \
  policies="$policy_name"
