#!/usr/bin/env bash

set -e -o pipefail

POSITIONAL_ARGS=()

BEGIN_FROM_MIGRATION=0
MIGRATION_PREFIX="migration-"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -b | --begin-from-migration)
    BEGIN_FROM_MIGRATION="$2"
    shift
    shift
    ;;
  -e | --migrate-to)
    MIGRATE_TO="$2"
    shift
    shift
    ;;
  -t | --tag-prefix)
    MIGRATION_PREFIX="$2"
    shift
    shift
    ;;
  -d | --dry-run)
    DRY_RUN="true"
    shift
    ;;
  *)
    echo "Unexpected option: $1"
    exit 1

    ;;
  esac
done

CURRENT_MIGRATION_NUMBER=${BEGIN_FROM_MIGRATION}

while true; do
  MIGRATION_TAG_NAME="${MIGRATION_PREFIX}${CURRENT_MIGRATION_NUMBER}"

  echo CURRENT_MIGRATION_NUMBER="${CURRENT_MIGRATION_NUMBER}"
  echo MIGRATION_TAG_NAME="${MIGRATION_TAG_NAME}"

  echo -e "\n\e[32mCheckout git tag ${MIGRATION_TAG_NAME}\e[0m\n"
  if [ $DRY_RUN != true ]; then
    git checkout "${MIGRATION_TAG_NAME}"
  fi

  echo -e "\n\e[32mStart migration\e[0m\n"
  if [ $DRY_RUN != true ]; then
    ./run.sh migrate
  fi

  CURRENT_MIGRATION_NUMBER=$((CURRENT_MIGRATION_NUMBER + 1))
  echo -e "\n\e[32mNext tag name: ${CURRENT_MIGRATION_NUMBER}\e[0m\n"

done
