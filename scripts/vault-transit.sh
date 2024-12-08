#!/usr/bin/env bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"

vault secrets enable transit

vault write -f transit/keys/image_signing_key
