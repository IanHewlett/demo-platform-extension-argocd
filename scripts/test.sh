#!/usr/bin/env bash
set -eo pipefail

echo "Run all spec tests in test/spec folder"
rspec test/spec/*.rb
