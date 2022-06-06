#!/usr/bin/env bash

set -e -o pipefail

BEGIN_FROM_MIGRATION=0
MIGRATION_PREFIX="migration-"
DRY_RUN=false
MIGRATION_COMMAND_PARAMS=""

function show_how_to_use() {
  echo -e "usage: \e[32m./migrate.sh\e[0m [cmd1] [cmd2] [cmd3]"
  echo -e ""
  echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
  echo -e "   \e[36m-b | --begin-from-migration\e[0m       from which migration should start"
  echo -e "   \e[36m-m | --migrate-to\e[0m                 which migration is the end"
  echo -e "   \e[36m-t | --tag-prefix\e[0m                 tag prefix for migration"
  echo -e "   \e[36m-d | --dry-run\e[0m                    run without real migration"
  echo -e "   \e[36m-c | --migration-command-params\e[0m   add extra params to migrate command"
  echo -e "   \e[34mwithout any parameters\e[0m            run with defaults"
  echo -e ""
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
  -b | --begin-from-migration)
    BEGIN_FROM_MIGRATION="$2"
    shift
    shift
    ;;
  -m | --migrate-to)
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
  -c | --migration-command-params)
    MIGRATION_COMMAND_PARAMS="$2"
    shift
    shift
    ;;
  -h | --help)
    show_how_to_use
    shift
    ;;
  *)
    echo "Unexpected option: $1"
    show_how_to_use
    exit 1
    ;;
  esac
done

CURRENT_MIGRATION_NUMBER=${BEGIN_FROM_MIGRATION}

while true; do
  MIGRATION_TAG_NAME="${MIGRATION_PREFIX}${CURRENT_MIGRATION_NUMBER}"

  if [ "$(git tag --list "${MIGRATION_TAG_NAME}")" ]; then
    echo -e "\n\e[32mCheckout git tag ${MIGRATION_TAG_NAME}\e[0m\n"
    if [[ $DRY_RUN != true ]]; then
      git checkout "${MIGRATION_TAG_NAME}"
    fi

    echo -e "\n\e[32mStart migration\e[0m\n"
    if [[ $DRY_RUN != true ]]; then
      ./run.sh migrate ${MIGRATION_COMMAND_PARAMS}
    fi

    if [[ "${MIGRATE_TO}" == "${CURRENT_MIGRATION_NUMBER}" ]]; then
      echo -e "\n\e[32mFinishing migration at ${CURRENT_MIGRATION_NUMBER}\e[0m\n"
      exit 0
    else
      CURRENT_MIGRATION_NUMBER=$((CURRENT_MIGRATION_NUMBER + 1))
      echo -e "\n\e[32mNext tag number: ${CURRENT_MIGRATION_NUMBER}\e[0m\n"
    fi
  else
    echo -e "\n\e[31mTag ${MIGRATION_TAG_NAME} does not exist. Skipping tag.\e[0m\n"
  fi

  if [[ "${MIGRATE_TO}" == "${CURRENT_MIGRATION_NUMBER}" ]]; then
    echo -e "\n\e[32mFinishing migration at ${CURRENT_MIGRATION_NUMBER}\e[0m\n"
    exit 0
  else
    CURRENT_MIGRATION_NUMBER=$((CURRENT_MIGRATION_NUMBER + 1))
    echo -e "\n\e[32mThe next tag number: ${CURRENT_MIGRATION_NUMBER}\e[0m\n"
  fi

done
