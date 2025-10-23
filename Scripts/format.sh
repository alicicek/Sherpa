#!/bin/bash
set -euo pipefail

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "swiftformat not found. Install via Homebrew: brew install swiftformat" >&2
  exit 1
fi

swiftformat . --config Config/.swiftformat "$@"
