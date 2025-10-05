#!/usr/bin/env bash
set -euo pipefail
TEXT="${1:-}"; shift || true

echo "${TEXT}"
echo "${TEXT}"

case "${BLOCK_BUTTON:-}" in
  1) i3-msg -q exec -- "$@" & ;;
esac
