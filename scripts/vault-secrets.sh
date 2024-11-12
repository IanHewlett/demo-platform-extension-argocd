#!/usr/bin/env bash
vault secrets enable -path=secret kv-v2
vault kv put secret/svc/github \
  token_username="git" \
  image_pull_token="$GITHUB_TOKEN"
vault secrets enable -path=avp kv-v2
vault kv put avp/test sample=secret
vault secrets enable -path=test kv-v2
vault kv put test/svc/vault vault_address="http://vault.vault.svc.cluster.local:8200"
