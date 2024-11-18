#!/usr/bin/env bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"
vault secrets enable -path=pki-local pki || true
vault secrets tune -max-lease-ttl=87600h pki-local
vault write -field=certificate pki-local/root/generate/internal common_name="istio-ca-vault" ttl=87600h > CA_cert.crt
vault write pki-local/config/urls issuing_certificates="http://vault.vault:8200/v1/pki/ca" crl_distribution_points="http://vault.vault:8200/v1/pki/crl"
vault secrets enable -path=pki-int-local-minikube-us-east-0 pki || true
vault secrets tune -max-lease-ttl=43800h pki-int-local-minikube-us-east-0
vault write -format=json pki-int-local-minikube-us-east-0/intermediate/generate/internal common_name="Istio-ca Intermediate Authority1" | jq -r '.data.csr' > pki_intermediate1.csr
vault write -format=json pki-local/root/sign-intermediate csr=@pki_intermediate1.csr format=pem ttl="43800h" | jq -r '.data.certificate' > intermediate1.cert.pem
cat intermediate1.cert.pem > intermediate1.chain.pem
cat CA_cert.crt >> intermediate1.chain.pem
vault write pki-int-local-minikube-us-east-0/intermediate/set-signed certificate=@intermediate1.chain.pem
vault write pki-int-local-minikube-us-east-0/roles/istio-ca-local-minikube-us-east-0 \
    allowed_domains=istio-ca \
    allow_any_name=true  \
    enforce_hostnames=false \
    require_cn=false \
    allowed_uri_sans="spiffe://*" \
    max_ttl=72h
