#!/usr/bin/env bash

set -e -o pipefail

function show_how_to_use() {
  echo -e "usage: \e[32m./migrate.sh\e[0m [cmd1] [cmd2] [cmd3]"
  echo -e ""
  echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
  echo -e "   \e[36m-s | --start-from-migration\e[0m       from which migration should start"
  echo -e "   \e[36m-e | --migrate-to\e[0m                 which migration is the end"
  echo -e "   \e[36m-p | --tag-prefix\e[0m                 TAG prefix for migration"
  echo -e "   \e[36m-d | --dry-run\e[0m                    run without real migration. Testing is easier in this mode"
  echo -e "   \e[36m-c | --migration-command-params\e[0m   add extra params to migrate command e.g.:"
  echo -e "                                     migrationlogs which commits to ipor-migration-state "
  echo -e "   \e[34m     without any parameters\e[0m       run with defaults"
  echo -e ""
  exit 0
}

START_FROM_MIGRATION=0
MIGRATION_PREFIX="migration-"
DRY_RUN=false
MIGRATION_COMMAND_PARAMS=""
MIGRATE_TO=999999999                 # without migrate-to arg use 'infinity' value as default

ENV_FILE="$(pwd)/.env"

if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
  echo -e "\n\e[32m${ENV_FILE} file was read\e[0m\n"
fi

if [ -z "${ENV_PROFILE}" ]; then
  echo -e "\n\e[31mEnvironment variable ENV_PROFILE is not set\e[0m\n"
  exit
fi

if [ -z "${ETH_BC_NETWORK_NAME}" ]; then
  echo -e "\n\e[31mEnvironment variable ETH_BC_NETWORK_NAME is not set\e[0m\n"
  exit
fi

LAST_COMPLETED_MIGRATION_FILE_PATH=".ipor/${ENV_PROFILE}-${ETH_BC_NETWORK_NAME}-last-completed-migration.json"

if [ -f "${LAST_COMPLETED_MIGRATION_FILE_PATH}" ]; then
  LAST_COMPLETED_MIGRATION_NUMBER=$(jq -r ".lastCompletedMigration" "${LAST_COMPLETED_MIGRATION_FILE_PATH}")
  START_FROM_MIGRATION=$((LAST_COMPLETED_MIGRATION_NUMBER + 1))
fi

while [[ $# -gt 0 ]]; do
  case $1 in
  -s | --start-from-migration)
    START_FROM_MIGRATION="$2"
    shift
    shift
    ;;
  -e | --migrate-to)
    MIGRATE_TO="$2"
    shift
    shift
    ;;
  -p | --tag-prefix)
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

MIGRATION_REGEX_PATTERN="^${MIGRATION_PREFIX}([0-9])+$"
TAGS_LIST=$(git tag --list | grep -E "${MIGRATION_REGEX_PATTERN}" | sort -V)

for TAG in $TAGS_LIST; do
  [[ $TAG =~ $MIGRATION_REGEX_PATTERN ]]
  TAG_NUMBER=${BASH_REMATCH[1]}

  if [[ "${TAG_NUMBER}" -ge "${START_FROM_MIGRATION}" ]] && [[ "${TAG_NUMBER}" -le "${MIGRATE_TO}" ]]; then
    echo -e "\n\e[32mCheckout git tag ${TAG}\e[0m\n"
    if [[ $DRY_RUN != true ]]; then
      git checkout "${TAG}"
    fi

    echo -e "\n\e[32mStart migration from git tag ${TAG}\e[0m\n"
    if [[ $DRY_RUN != true ]]; then
      # shellcheck disable=SC2086
      ./run.sh migrate ${MIGRATION_COMMAND_PARAMS}
    fi
  else
    echo "Skipping tag ${TAG}".
  fi

done
