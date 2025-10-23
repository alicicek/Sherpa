#!/bin/bash
set -euo pipefail

if ! command -v periphery >/dev/null 2>&1; then
  echo "periphery not found. Install via Homebrew: brew install peripheryapp/periphery/periphery" >&2
  exit 1
fi

periphery scan --config Config/periphery.yml "$@"
