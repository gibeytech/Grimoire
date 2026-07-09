#!/usr/bin/env bash

set -euo pipefail

PROFILE="gibeytech"
DRY_RUN="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --apply)
      DRY_RUN="false"
      shift
      ;;
    *)
      echo "Argument inconnu: $1"
      echo "Usage: ./install.sh [--profile gibeytech] [--dry-run|--apply]"
      exit 1
      ;;
  esac
done

echo "== Grimoire V3 Installer =="
echo "Profile : ${PROFILE}"
echo "Dry-run : ${DRY_RUN}"
echo ""

lua tools/installer-slice.lua "${PROFILE}" "${DRY_RUN}"
