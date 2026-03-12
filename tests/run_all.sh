#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

./tests/test_examples.sh
./tests/test_cli_features.sh

echo "[PASS] all tests passed"
