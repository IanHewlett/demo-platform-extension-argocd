#!/usr/bin/env bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"
export PKI_MESH="pki-$1"
export PKI_CLUSTER="pki-int-$2"
export ISTIO_CA_ROLE="istio-ca-$2"

vault secrets enable -path="$PKI_MESH" pki || true
vault secrets tune -max-lease-ttl=87600h "$PKI_MESH"
vault write -field=certificate \
  "$PKI_MESH"/root/generate/internal \
  common_name="istio-ca-vault" ttl=87600h > CA_cert.crt
vault write \
  "$PKI_MESH"/config/urls \
  issuing_certificates="http://vault.vault:8200/v1/pki/ca" \
  crl_distribution_points="http://vault.vault:8200/v1/pki/crl"

vault secrets enable -path="$PKI_CLUSTER" pki || true
vault secrets tune -max-lease-ttl=43800h "$PKI_CLUSTER"
vault write -format=json \
  "$PKI_CLUSTER"/intermediate/generate/internal \
  common_name="Istio-ca Intermediate Authority1" \
  | jq -r '.data.csr' > pki_intermediate1.csr
vault write -format=json \
  "$PKI_MESH"/root/sign-intermediate \
  csr=@pki_intermediate1.csr format=pem ttl="43800h" \
  | jq -r '.data.certificate' > intermediate1.cert.pem

cat intermediate1.cert.pem > intermediate1.chain.pem
cat CA_cert.crt >> intermediate1.chain.pem

vault write \
  "$PKI_CLUSTER"/intermediate/set-signed \
  certificate=@intermediate1.chain.pem
vault write \
  "$PKI_CLUSTER/roles/$ISTIO_CA_ROLE" \
  allowed_domains=istio-ca \
  allow_any_name=true  \
  enforce_hostnames=false \
  require_cn=false \
  allowed_uri_sans="spiffe://*" \
  max_ttl=72h

rm -rf CA_cert.crt
rm -rf pki_intermediate1.csr
rm -rf intermediate1.cert.pem
rm -rf intermediate1.chain.pem
