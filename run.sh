#!/usr/bin/env bash

set -e -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV_FILE_NAME=".env"
ENV_FILE="${DIR}/${ENV_FILE_NAME}"

# global vars that shouldn't be reset
LAST_MIGRATION_DATE=""
LAST_COMMIT_HASH=""
LAST_COMMIT_SHORT_HASH=""
LAST_MIGRATION_NUMBER=""

# Variables set by .env file
GLOBAL_AWS_PROFILE=""
ENV_PROFILE="${ENV_PROFILE:-}"
SC_MIGRATION_STATE_REPO=""
ETH_BC_NETWORK_NAME="${ETH_BC_NETWORK_NAME:-}"
ENV_CONFIG_BUCKET="${ENV_CONFIG_BUCKET:-ipor-env}"

# global vars that can be reset
function refresh_global_variables() {
  ENV_CONTRACTS_FILE_NAME="contracts.zip"
  local ENV_CONTRACTS_ROOT_DIR="app/src"
  ENV_CONTRACTS_DIR="${ENV_CONTRACTS_ROOT_DIR}/contracts"
  ENV_CONTRACTS_ZIP_DEST="${ENV_CONTRACTS_ROOT_DIR}/${ENV_CONTRACTS_FILE_NAME}"
  ENV_CONTRACTS_ZIP_RMT="${ENV_PROFILE}/${ENV_CONTRACTS_FILE_NAME}"

  local ETH_BC_DOCKERFILE_PATH="${CONTAINERS_DIR}/eth-bc"

  AWS_REGION="eu-central-1"

  IPOR_MIGRATION_STATE_DIR=".ipor"
  SC_MIGRATION_STATE_REPO_DIR="${DIR}/../${SC_MIGRATION_STATE_REPO}"

  local ENVS_DIR="${ETH_BC_DOCKERFILE_PATH}/envs"
  local ETH_BC_DUMP_CONFIG_DIR="${ENVS_DIR}/{ENV}"

  ETH_BC_GEN_ENV_CONTRACTS_FILE_PATH="${ETH_BC_DUMP_CONFIG_DIR}/${ENV_CONTRACTS_FILE_NAME}"
  ETH_BC_GEN_ENV_DUMP_CONFIG_DIR="${ETH_BC_DUMP_CONFIG_DIR}/"

  GEN_IPOR_ADDRESSES_FILE="{ENV}-${ETH_BC_NETWORK_NAME}-ipor-addresses.json"
  GEN_IPOR_ADDRESSES_FILE_PATH="${IPOR_MIGRATION_STATE_DIR}/${GEN_IPOR_ADDRESSES_FILE}"
  GEN_IPOR_ADDRESSES_FILE_RMT="${ENV_PROFILE}/${GEN_IPOR_ADDRESSES_FILE}"
  GEN_MIGRATION_COMMIT_FILE_PATH="${IPOR_MIGRATION_STATE_DIR}/{ENV}-${ETH_BC_NETWORK_NAME}-migration-commit.txt"
  GEN_LAST_COMPLETED_MIGRATION_FILE_PATH="${IPOR_MIGRATION_STATE_DIR}/{ENV}-${ETH_BC_NETWORK_NAME}-last-completed-migration.json"
}

function read_env_file() {
  local ENV_FILE_PATH="${1}"
  if [ -f "${ENV_FILE_PATH}" ]; then
    set -a
    source "${ENV_FILE_PATH}"
    set +a
    echo -e "\n\e[32m${ENV_FILE_PATH} file was read\e[0m\n"
  fi
  refresh_global_variables
}

# Read .env file
read_env_file "${ENV_FILE}"

IS_MIGRATE_SC="NO"
IS_MIGRATE_WITH_CLEAN_SC="NO"
IS_HELP="NO"
IS_PUBLISH_ARTIFACTS="NO"
COMMIT_MIGRATION_STATE="NO"

while test $# -gt 0; do
  case "$1" in
  migrate | m)
    IS_MIGRATE_SC="YES"
    ;;
  migrateclean | mc)
    IS_MIGRATE_WITH_CLEAN_SC="YES"
    ;;
  migrationlogs | mlogs)
    COMMIT_MIGRATION_STATE="YES"
    ;;
  publish | p)
    IS_PUBLISH_ARTIFACTS="YES"
    ;;
  help | h | ?)
    IS_HELP="YES"
    ;;
  *)
    echo -e "\e[33mWARNING!\e[0m ${1} - command not found"
    ;;
  esac
  shift
done

################################### FUNCTIONS ###################################

function get_aws_profile_cmd() {
  local WITH_PROFILE=""
  if [ -z "${GLOBAL_AWS_PROFILE}" ]; then
    WITH_PROFILE=""
  else
    WITH_PROFILE="--profile"
  fi
  echo "${WITH_PROFILE}"
}

function get_aws_profile_name() {
  local WITH_PROFILE=""
  if [ -z "${GLOBAL_AWS_PROFILE}" ]; then
    WITH_PROFILE=""
  else
    WITH_PROFILE="${GLOBAL_AWS_PROFILE}"
  fi
  echo "${WITH_PROFILE}"
}

function create_contracts_zip() {
  if [ -f "${ENV_CONTRACTS_ZIP_DEST}" ]; then
    rm -v "${ENV_CONTRACTS_ZIP_DEST}"
  fi
  zip -r -j -q "${ENV_CONTRACTS_ZIP_DEST}" "${ENV_CONTRACTS_DIR}"
  echo -e "${ENV_CONTRACTS_ZIP_DEST} file was created"
}

function put_file_to_bucket() {
  local FILE_NAME="${1}"
  local FILE_KEY="${2}"
  local PROFILE_CMD
  local PROFILE_NAME

  PROFILE_CMD=$(get_aws_profile_cmd)
  PROFILE_NAME=$(get_aws_profile_name)

  aws s3api put-object --bucket "${ENV_CONFIG_BUCKET}" --key "${FILE_KEY}" --body "${FILE_NAME}" --region "${AWS_REGION}" "${PROFILE_CMD}" "${PROFILE_NAME}"
  echo -e "${FILE_KEY} file was published"
}

function create_migration_logs_dir_files() {
  local date_now="${1}"
  local env_name="${2}"

  cd "${DIR}"
  mkdir -p "${IPOR_MIGRATION_STATE_DIR}/"
  mkdir -p ".logs/${env_name}/compile/"
  mkdir -p ".logs/${env_name}/migrate/"

  touch ".logs/${env_name}/compile/${date_now}_compile.log"
  touch ".logs/${env_name}/migrate/${date_now}_migrate.log"
}

function get_commit_hash() {
  cd "${DIR}"
  local COMMIT_HASH
  COMMIT_HASH=$(git rev-parse HEAD)
  echo "${COMMIT_HASH}"
}

function get_branch_name() {
  cd "${DIR}"
  local BRANCH_NAME
  BRANCH_NAME=$(git branch --show-current)
  echo "${BRANCH_NAME}"
}

function create_commit_file() {
  local commit_hash="${1}"
  local ENV_NAME="${2}"

  local MIGRATION_COMMIT_FILE_PATH
  MIGRATION_COMMIT_FILE_PATH="$(get_path_with_env "${GEN_MIGRATION_COMMIT_FILE_PATH}" "${ENV_NAME}")"

  rm -f -v "${MIGRATION_COMMIT_FILE_PATH}"
  touch "${MIGRATION_COMMIT_FILE_PATH}"

  echo "${commit_hash}" >>"${MIGRATION_COMMIT_FILE_PATH}"
  echo -e "Migration commit hash: ${commit_hash}"
}

function get_date_and_time() {
  local DATE_NOW
  DATE_NOW=$(date "+%F_%H-%M-%S")
  echo "${DATE_NOW}"
}

function read_last_migration() {
  local DATE_NOW
  DATE_NOW=$(date "+%F_%H-%M-%S")
  echo "${DATE_NOW}"
}

function update_global_state_vars() {
  LAST_MIGRATION_DATE=$(get_date_and_time)
  LAST_COMMIT_HASH=$(get_commit_hash)
  LAST_COMMIT_SHORT_HASH="${LAST_COMMIT_HASH:0:7}"
}

function get_last_migration_number() {
  local ENV_NAME="${1}"
  local LAST_COMPLETED_MIGRATION_FILE_PATH
  LAST_COMPLETED_MIGRATION_FILE_PATH="$(get_path_with_env "${GEN_LAST_COMPLETED_MIGRATION_FILE_PATH}" "${ENV_NAME}")"
  local LAST_COMPLETED_MIGRATION
  LAST_COMPLETED_MIGRATION=$(jq -r ".lastCompletedMigration" "${LAST_COMPLETED_MIGRATION_FILE_PATH}")
  local LAST_MIGRATION_NUMBER
  LAST_MIGRATION_NUMBER=$(printf "%04d" "${LAST_COMPLETED_MIGRATION}")
  echo "${LAST_MIGRATION_NUMBER}"
}

function clean_openzeppelin_migration_file() {
  local file_name=""
  case ${ETH_BC_NETWORK_ID} in
  1)
    file_name="mainnet"
    ;;
  4)
    file_name="rinkeby"
    ;;
  5)
    file_name="goerli"
    ;;
  *)
    file_name="unknown-${ETH_BC_NETWORK_ID}"
    ;;
  esac
  rm -f -v ".openzeppelin/${file_name}.json"
}

function prepare_migration_state_files_structure() {
  update_global_state_vars
  create_migration_logs_dir_files "${LAST_MIGRATION_DATE}" "${ENV_PROFILE}"
  create_commit_file "${LAST_COMMIT_HASH}" "${ENV_PROFILE}"
}

function rm_smart_contracts_migrations_state_file() {
  rm -f -v ".openzeppelin/unknown-${ETH_BC_NETWORK_ID}.json"
}

function run_smart_contract_migrations() {
  cd "${DIR}"

  echo -e "\n\e[32mMigrate Smart Contracts to Ethereum blockchain...\e[0m\n"

  prepare_migration_state_files_structure

  npm run compile:truffle 2>&1 | tee ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log"
  npm run export-abi
  export ETH_BC_NETWORK_NAME
  npm run migrate:truffle 2>&1 | tee ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log"

  cp "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_PATH}" "${ENV_PROFILE}")" "app/src/$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE}" "${ENV_PROFILE}")"
}

function clean_migration_files() {
  local ENV_NAME="${1}"

  cd "${DIR}"

  echo -e "Remove migration files:"
  rm -f -v "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_PATH}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${GEN_MIGRATION_COMMIT_FILE_PATH}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${GEN_LAST_COMPLETED_MIGRATION_FILE_PATH}" "${ENV_NAME}")"
}

function run_clean_smart_contract_migrations() {
  cd "${DIR}"
  echo -e "\n\e[32mMigrate with clean Smart Contracts to Ethereum blockchain...\e[0m\n"

  clean_openzeppelin_migration_file
  rm -rf -v app/src/contracts/
  clean_migration_files "${ENV_PROFILE}"

  prepare_migration_state_files_structure

  npm run compile:truffle 2>&1 | tee ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log"
  npm run export-abi
  export ETH_BC_NETWORK_NAME
  npm run migrate:truffle-reset 2>&1 | tee ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log"

  cp "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_PATH}" "${ENV_PROFILE}")" "app/src/$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE}" "${ENV_PROFILE}")"
}

function get_path_with_env() {
  local SOURCE_PATH="${1}"
  local ENV_NAME="${2}"
  local TARGET_PATH=${SOURCE_PATH/\{ENV\}/$ENV_NAME}
  echo "${TARGET_PATH}"
}

function copy_smart_contract_json_files() {
  local ENV_NAME="${1}"

  cd "${DIR}"
  create_contracts_zip
  echo "Copy: ${ENV_CONTRACTS_ZIP_DEST} into: $(get_path_with_env "${ETH_BC_GEN_ENV_CONTRACTS_FILE_PATH}" "${ENV_NAME}")"
  cp "${ENV_CONTRACTS_ZIP_DEST}" "$(get_path_with_env "${ETH_BC_GEN_ENV_CONTRACTS_FILE_PATH}" "${ENV_NAME}")"
}

function copy_ipor_migrations_dir() {
  local ENV_NAME="${1}"

  cd "${DIR}"
  echo "Copy: ${IPOR_MIGRATION_STATE_DIR} into: $(get_path_with_env "${ETH_BC_GEN_ENV_DUMP_CONFIG_DIR}" "${ENV_NAME}")"
  cp -r "${IPOR_MIGRATION_STATE_DIR}" "$(get_path_with_env "${ETH_BC_GEN_ENV_DUMP_CONFIG_DIR}" "${ENV_NAME}")"
}

function copy_env_files() {
  local ENV_NAME="${1}"

  copy_smart_contract_json_files "${ENV_NAME}"
  copy_ipor_migrations_dir "${ENV_NAME}"
}

function create_migrated_env_files() {
  local SRC_ENV_NAME="${1}"
  local TRG_ENV_NAME="${2}"

  cd "${DIR}"

  cp "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_PATH}" "${SRC_ENV_NAME}")" "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_PATH}" "${TRG_ENV_NAME}")"
  cp "$(get_path_with_env "${GEN_MIGRATION_COMMIT_FILE_PATH}" "${SRC_ENV_NAME}")" "$(get_path_with_env "${GEN_MIGRATION_COMMIT_FILE_PATH}" "${TRG_ENV_NAME}")"
  cp "$(get_path_with_env "${GEN_LAST_COMPLETED_MIGRATION_FILE_PATH}" "${SRC_ENV_NAME}")" "$(get_path_with_env "${GEN_LAST_COMPLETED_MIGRATION_FILE_PATH}" "${TRG_ENV_NAME}")"
}

################################### COMMANDS ###################################

if [ $IS_MIGRATE_SC = "YES" ]; then
  run_smart_contract_migrations
fi

if [ $IS_MIGRATE_WITH_CLEAN_SC = "YES" ]; then
  if [[ $ETH_BC_NETWORK_ID == 1 ]]; then
    echo "ERROR! You cannot use migration with clean on Mainnet environment!"
    exit 1
  fi
  if [[ $ETH_BC_NETWORK_ID == 5 ]]; then
    echo "ERROR! You cannot use migration with clean on Goerli environment!"
    exit 1
  fi
  run_clean_smart_contract_migrations
fi

if [ $COMMIT_MIGRATION_STATE = "YES" ]; then

  cd "${DIR}"
  LAST_MIGRATION_NUMBER=$(get_last_migration_number "${ENV_PROFILE}")

  profile_dir="${SC_MIGRATION_STATE_REPO_DIR}/${ENV_PROFILE}/${SC_REPO}"
  migration_date_dir="${profile_dir}/migrations/${LAST_MIGRATION_NUMBER}_${LAST_COMMIT_SHORT_HASH}_${LAST_MIGRATION_DATE}"
  current_state_dir="${profile_dir}/current_state"

  echo "Copy migration state to: ${migration_date_dir}"

  cd "${SC_MIGRATION_STATE_REPO_DIR}"
  echo "Git pull: ${SC_MIGRATION_STATE_REPO}"
  git pull

  cd "${DIR}"

  create_contracts_zip

  mkdir -p "${migration_date_dir}/logs"

  cp -R ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log" "${migration_date_dir}/logs"
  cp -R ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log" "${migration_date_dir}/logs"
  cp -R "${IPOR_MIGRATION_STATE_DIR}/" "${migration_date_dir}"
  cp -R .openzeppelin/ "${migration_date_dir}"

  cp "${ENV_CONTRACTS_ZIP_DEST}" "${migration_date_dir}/${ENV_CONTRACTS_FILE_NAME}"

  cd "${SC_MIGRATION_STATE_REPO_DIR}"
  echo "Git add: ${SC_MIGRATION_STATE_REPO} - details"
  git add .

  echo "Git commit: ${SC_MIGRATION_STATE_REPO} | with msg: Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE} - details"
  git commit -m "Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE} - details"

  cd "${DIR}"

  mkdir -p "${current_state_dir}"

  cp -R "${IPOR_MIGRATION_STATE_DIR}/" "${current_state_dir}"
  cp -R .openzeppelin/ "${current_state_dir}"

  cd "${SC_MIGRATION_STATE_REPO_DIR}"
  echo "Git add: ${SC_MIGRATION_STATE_REPO} - current state"
  git add .

  echo "Git commit: ${SC_MIGRATION_STATE_REPO} | with msg: Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE} - current state"
  git commit -m "Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE} - current state"

  echo "Git push: ${SC_MIGRATION_STATE_REPO}"
  git push
  cd "${DIR}"
fi

if [ $IS_PUBLISH_ARTIFACTS = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mPublish artifacts to S3 bucket: ${ENV_CONFIG_BUCKET}/${ENV_PROFILE}\e[0m\n"

  create_contracts_zip

  put_file_to_bucket "${ENV_CONTRACTS_ZIP_DEST}" "${ENV_CONTRACTS_ZIP_RMT}"
  put_file_to_bucket "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_PATH}" "${ENV_PROFILE}")" "$(get_path_with_env "${GEN_IPOR_ADDRESSES_FILE_RMT}" "${ENV_PROFILE}")"
fi

if [ $IS_HELP = "YES" ]; then
  echo -e "usage: \e[32m./run.sh\e[0m [cmd1] [cmd2] [cmd3]"
  echo -e ""
  echo -e "commands can be joined together, order of commands doesn't matter, allowed commands:"
  echo -e "   \e[36mmigrate\e[0m|\e[36mm\e[0m           Compile and migrate Smart Contracts to blockchain"
  echo -e "   \e[36mmigrationlogs|\e[36mmlogs\e[0m Commit logs after migration"
  echo -e "   \e[36mmigrateclean\e[0m|\e[36mmc\e[0m     Compile and migrate with clean Smart Contracts to blockchain"
  echo -e "   \e[36mpublish\e[0m|\e[36mp\e[0m           Publish build artifacts to S3 bucket"
  echo -e "   \e[36mhelp\e[0m|\e[36mh\e[0m|\e[36m?\e[0m            Show help"
  echo -e ""
  exit 0
fi
