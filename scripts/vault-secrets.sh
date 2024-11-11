#!/usr/bin/env bash
vault secrets enable -path=secret kv-v2
vault kv put secret/svc/github \
  token_username="git" \
  image_pull_token="$GITHUB_TOKEN"
vault secrets enable -path=avp kv-v2
vault kv put avp/test sample=secret