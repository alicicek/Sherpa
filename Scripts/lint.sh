#!/bin/bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "swiftlint not found. Install via Homebrew: brew install swiftlint" >&2
  exit 1
fi

swiftlint --config Config/.swiftlint.yml --strict "$@"
