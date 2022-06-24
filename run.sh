#!/usr/bin/env bash

set -e -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV_FILE_NAME=".env"
ENV_FILE="${DIR}/${ENV_FILE_NAME}"
ENV_LOCAL_TEMPLATE_FILE="${DIR}/.env-local.j2"
GLOBAL_AWS_PROFILE=""
ROOT_PASSWORD=""
WITH_PROFILE=""

function read_env_file() {
  local ENV_FILE_PATH="${1}"
  if [ -f "${ENV_FILE_PATH}" ]; then
    set -a
    source "${ENV_FILE_PATH}"
    set +a
    echo -e "\n\e[32m${ENV_FILE_PATH} file was read\e[0m\n"
  fi
}

read_env_file "${ENV_FILE}"

ENV_CONFIG_BUCKET="ipor-env"

ENV_CONFIG_FILE_SRC="smart-contract-addresses.yaml.j2"
ENV_CONFIG_FILE_DEST="smart-contract-addresses.yaml"
ENV_CONFIG_FILE_RMT="${ENV_PROFILE}/${ENV_CONFIG_FILE_DEST}"

ENV_CONTRACTS_FILE_NAME="contracts.zip"
ENV_CONTRACTS_ROOT_DIR="app/src"
ENV_CONTRACTS_DIR="${ENV_CONTRACTS_ROOT_DIR}/contracts"
ENV_CONTRACTS_ZIP_DEST="${ENV_CONTRACTS_ROOT_DIR}/${ENV_CONTRACTS_FILE_NAME}"
ENV_CONTRACTS_ZIP_RMT="${ENV_PROFILE}/${ENV_CONTRACTS_FILE_NAME}"

CONTAINERS_DIR="${DIR}/containers"
ETH_BC_CONTAINER="ipor-protocol-eth-bc"
ETH_EXP_CONTAINER="ipor-protocol-eth-explorer"
ETH_EXP_POSTGRES_CONTAINER="ipor-protocol-eth-exp-postgres"

ETH_BC_DATA_VOLUME="ipor-protocol-eth-bc-data"
ETH_EXP_DATA_VOLUME="ipor-protocol-eth-exp-postgres-data"

NGINX_ETH_BC_CONTAINER="ipor-protocol-nginx-eth-bc"

ETH_BC_IMAGE_NAME="ipor-geth"
ETH_BC_DOCKERFILE_PATH="${CONTAINERS_DIR}/eth-bc"

ETH_BC_BLOCK_PER_TRANSACTION_TAG_NAME="s0"
ETH_BC_BLOCK_PER_INTERVAL_TAG_NAME="s12"
ETH_BC_ITF_TAG_NAME="itf"

AWS_REGION="eu-central-1"
AWS_DOCKER_REGISTRY="964341344241.dkr.ecr.eu-central-1.amazonaws.com"

ETH_BC_URL="http://localhost:9545"

IPOR_MIGRATION_STATE_DIR=".ipor"
MIGRATION_STATE_REPO_DIR="${DIR}/../${MIGRATION_STATE_REPO}"

ENVS_DIR="${ETH_BC_DOCKERFILE_PATH}/envs"
ETH_BC_DUMP_DIR="${ETH_BC_DOCKERFILE_PATH}/eth-bc-dump"
ETH_BC_DUMP_FILE="eth-bc-dump.tar"
ETH_BC_DUMP_PATH="${ETH_BC_DUMP_DIR}/${ETH_BC_DUMP_FILE}"
ETH_DATA_DIR=".ethereum"
ETH_BC_DUMP_CONFIG_DIR="${ENVS_DIR}/{ENV}"
ETH_BC_DUMP_J2_DIR="${ETH_BC_DOCKERFILE_PATH}/templates/env"
ENV_CREDENTIALS_VARIABLES_FILE="${ETH_BC_DOCKERFILE_PATH}/templates/credentials-variables.env"
ENV_LOCAL_VARIABLES_FILE="${ETH_BC_DUMP_CONFIG_DIR}/variables.env"

ETH_BC_GENESIS_J2_PATH="${ETH_BC_DUMP_J2_DIR}/genesis.json.j2"
ETH_BC_CONFIG_J2_PATH="${ETH_BC_DUMP_J2_DIR}/geth-config.toml.j2"
ETH_BC_KEY_PASSWORD_J2_PATH="${ETH_BC_DUMP_J2_DIR}/key-password.txt.j2"
ETH_BC_MINER_KEY_J2_PATH="${ETH_BC_DUMP_J2_DIR}/miner.key.j2"

ETH_BC_GEN_VARIABLES_PATH="${ETH_BC_DUMP_CONFIG_DIR}/all-variables.env"
ETH_BC_GEN_GENESIS_PATH="${ETH_BC_DUMP_CONFIG_DIR}/genesis.json"
ETH_BC_GEN_CONFIG_PATH="${ETH_BC_DUMP_CONFIG_DIR}/geth-config.toml"
ETH_BC_GEN_KEY_PASSWORD_PATH="${ETH_BC_DUMP_CONFIG_DIR}/key-password.txt"
ETH_BC_GEN_MINER_KEY_PATH="${ETH_BC_DUMP_CONFIG_DIR}/miner.key"
ETH_BC_GEN_ENV_CONFIG_FILE_PATH="${ETH_BC_DUMP_CONFIG_DIR}/${ENV_CONFIG_FILE_DEST}"
ETH_BC_GEN_ENV_CONTRACTS_FILE_PATH="${ETH_BC_DUMP_CONFIG_DIR}/${ENV_CONTRACTS_FILE_NAME}"
ETH_BC_GEN_ENV_DUMP_CONFIG_DIR="${ETH_BC_DUMP_CONFIG_DIR}/"

GEN_IPOR_ADDRESSES_FILE_PATH="${IPOR_MIGRATION_STATE_DIR}/{ENV}-${ETH_BC_NETWORK_NAME}-ipor-addresses.json"
GEN_MIGRATION_COMMIT_FILE_PATH="${IPOR_MIGRATION_STATE_DIR}/{ENV}-${ETH_BC_NETWORK_NAME}-migration-commit.txt"
GEN_LAST_COMPLETED_MIGRATION_FILE_PATH="${IPOR_MIGRATION_STATE_DIR}/{ENV}-${ETH_BC_NETWORK_NAME}-last-completed-migration.json"

IPOR_COCKPIT_DOCKERFILE_PATH="${DIR}/app"
IPOR_COCKPIT_IMAGE_NAME="ipor-cockpit"
IPOR_COCKPIT_CONTAINER_DIR="${CONTAINERS_DIR}/cockpit"
IPOR_COCKPIT_ENV_CONFIG_J2_PATH="${IPOR_COCKPIT_CONTAINER_DIR}/.env.j2"
IPOR_COCKPIT_GEN_ENV_CONFIG_PATH="${IPOR_COCKPIT_DOCKERFILE_PATH}/.env"

IS_DOCKER_LOGIN="NO"
IS_MIGRATE_SC="NO"
IS_MIGRATE_WITH_CLEAN_SC="NO"
IS_BUILD_DOCKER="NO"
IS_CLEAN_BC="NO"
IS_RUN="NO"
IS_STOP="NO"
IS_HELP="NO"
IS_PUBLISH_ARTIFACTS="NO"
IS_NGINX_ETH_BC_RESTART="NO"
COMMIT_MIGRATION_STATE="NO"
IS_DOWNLOAD_DEPLOYED_SMART_CONTRACTS="NO"
IS_UPDATE_COCKPIT="NO"
IS_DUMP_ETH_BLOCKCHAIN="NO"
IS_CREATE_GETH_IMAGE="NO"
IS_RETAG_GETH_IMAGE="NO"

LAST_MIGRATION_DATE=""
LAST_COMMIT_HASH=""
LAST_COMMIT_SHORT_HASH=""
LAST_MIGRATION_NUMBER=""

CGI_IMAGE_TYPE=""
CGI_BRANCH_NAME=""
CGI_COMMIT_HASH=""
CGI_PUBLISH_ENABLED=""

if [ $# -eq 0 ]; then
  IS_RUN="YES"
fi

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
  build | b)
    IS_BUILD_DOCKER="YES"
    ;;
  run | r)
    IS_RUN="YES"
    IS_STOP="YES"
    ;;
  stop | s)
    IS_STOP="YES"
    ;;
  publish | p)
    IS_PUBLISH_ARTIFACTS="YES"
    ;;
  clean | c)
    IS_CLEAN_BC="YES"
    ;;
  nginx | n)
    IS_NGINX_ETH_BC_RESTART="YES"
    ;;
  update-cockpit | uc)
    IS_UPDATE_COCKPIT="YES"
    ;;
  download-deployed-smart-contracts | ddsc)
    IS_DOWNLOAD_DEPLOYED_SMART_CONTRACTS="YES"
    ;;
  dump-eth-blockchain | deb)
    IS_DUMP_ETH_BLOCKCHAIN="YES"
    ;;
  create-geth-image | cgi)
    IS_CREATE_GETH_IMAGE="YES"
    CGI_IMAGE_TYPE="${2}"
    CGI_PUBLISH_ENABLED="${3}"
    shift
    shift
    ;;
  retag-geth-image | rgi)
    IS_RETAG_GETH_IMAGE="YES"
    ;;
  docker-login | dl)
    IS_DOCKER_LOGIN="YES"
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

function set_smart_contract_address_in_env_config_file() {
  local VAR_NAME="${1}"
  local VAR_VALUE="${2}"
  sed -i "s/${VAR_NAME}.*/${VAR_NAME}: \"${VAR_VALUE}\"/" "${ENV_CONFIG_FILE_DEST}"
}

function get_smart_contract_address_from_json_file() {
  local FILE_NAME="${1}"
  local VAR_VALUE=$(jq -r '.networks[].address' "${ENV_CONTRACTS_DIR}/${FILE_NAME}")
  echo "${VAR_VALUE}"
}

function set_smart_contract_address_from_json_file() {
  local FILE_NAME="${1}"
  local VAR_NAME="${2}"
  local VAR_VALUE=$(get_smart_contract_address_from_json_file "${FILE_NAME}")
  set_smart_contract_address_in_env_config_file "${VAR_NAME}" "${VAR_VALUE}"
  echo "${VAR_VALUE}"
}

function call_smart_contract_method() {
  local SMART_CONTRACT_ADDRESS="${1}"
  local METHOD_SIGNATURE="${2}"

  local DATA_JSON=$(jq -n --arg SMART_CONTRACT_ADDRESS "${SMART_CONTRACT_ADDRESS}" --arg METHOD_SIGNATURE "${METHOD_SIGNATURE}" '{
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
          {
              "to": $SMART_CONTRACT_ADDRESS,
              "data": $METHOD_SIGNATURE
          },
          "latest"
      ],
      "id": 1
  }') || exit

  local RESULT=$(curl -s --location --request POST "${ETH_BC_URL}" \
    --header "Content-Type: application/json" \
    --data-raw "${DATA_JSON}")
  echo "${RESULT}"
}

function get_smart_contract_address_from_eth_method() {
  local SMART_CONTRACT_ADDRESS="${1}"
  local METHOD_SIGNATURE="${2}"

  local RESULT=$(call_smart_contract_method "${SMART_CONTRACT_ADDRESS}" "${METHOD_SIGNATURE}")

  local RESULT_ADDRESS=$(echo "${RESULT}" | jq -r ".result")
  echo "0x${RESULT_ADDRESS:(-40)}"
}

function set_smart_contract_address_from_eth_method() {
  local SMART_CONTRACT_ADDRESS="${1}"
  local METHOD_SIGNATURE="${2}"
  local VAR_NAME="${3}"

  local VAR_VALUE=$(get_smart_contract_address_from_eth_method "${SMART_CONTRACT_ADDRESS}" "${METHOD_SIGNATURE}")
  set_smart_contract_address_in_env_config_file "${VAR_NAME}" "${VAR_VALUE}"
  echo "${VAR_VALUE}"
}

function create_env_config_file() {
  cp "${ENV_CONFIG_FILE_SRC}" "${ENV_CONFIG_FILE_DEST}"

  local RESULT=""
  RESULT=$(set_smart_contract_address_from_json_file "MiltonUsdt.json" "milton_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonUsdc.json" "milton_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonDai.json" "milton_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "IporOracle.json" "ipor_oracle_address")
  RESULT=$(set_smart_contract_address_from_json_file "JosephUsdt.json" "joseph_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "JosephUsdc.json" "joseph_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "JosephDai.json" "joseph_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfMiltonUsdt.json" "itf_milton_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfMiltonUsdc.json" "itf_milton_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfMiltonDai.json" "itf_milton_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfIporOracle.json" "itf_ipor_oracle_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfJosephUsdt.json" "itf_joseph_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfJosephUsdc.json" "itf_joseph_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfJosephDai.json" "itf_joseph_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "CockpitDataProvider.json" "cockpit_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonFacadeDataProvider.json" "milton_facade_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "IporOracleFacadeDataProvider.json" "ipor_oracle_facade_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "MockTestnetTokenDai.json" "dai_mocked_address")
  RESULT=$(set_smart_contract_address_from_json_file "MockTestnetTokenUsdc.json" "usdc_mocked_address")
  RESULT=$(set_smart_contract_address_from_json_file "MockTestnetTokenUsdt.json" "usdt_mocked_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonStorageUsdt.json" "milton_storage_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonStorageUsdc.json" "milton_storage_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonStorageDai.json" "milton_storage_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonSpreadModel.json" "milton_spread_model_address")
  RESULT=$(set_smart_contract_address_from_json_file "TestnetFaucet.json" "testnet_faucet_address")
  RESULT=$(set_smart_contract_address_from_json_file "IpTokenUsdc.json" "ipor_ip_token_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "IpTokenUsdt.json" "ipor_ip_token_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "IpTokenDai.json" "ipor_ip_token_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "StanleyUsdc.json" "stanley_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "StanleyUsdt.json" "stanley_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "StanleyDai.json" "stanley_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfDataProvider.json" "itf_data_provider")

  echo -e "${ENV_CONFIG_FILE_DEST} file was created"
}

function get_aws_profile() {
  local WITH_PROFILE=""
  if [ -z "${GLOBAL_AWS_PROFILE}" ]; then
    WITH_PROFILE=""
  else
    WITH_PROFILE="--profile ${GLOBAL_AWS_PROFILE}"
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

  local WITH_PROFILE=$(get_aws_profile)

  aws s3api put-object --bucket "${ENV_CONFIG_BUCKET}" --key "${FILE_KEY}" --body "${FILE_NAME}" --region "${AWS_REGION}" ${WITH_PROFILE}
  echo -e "${FILE_KEY} file was published"
}

function remove_container() {
  local CONTAINER_NAME="${1}"
  local EXISTS=$(docker ps -a -q -f name="${CONTAINER_NAME}")
  if [ -n "$EXISTS" ]; then
    echo -e "Remove container: ${CONTAINER_NAME}\n"
    docker stop "${CONTAINER_NAME}"
    docker rm -v -f "${CONTAINER_NAME}"
  fi
}

function remove_volume() {
  local VOLUME_NAME="${1}"
  local EXISTS=$(docker volume ls -q -f name="${VOLUME_NAME}")
  if [ -n "$EXISTS" ]; then
    echo -e "Remove volume: ${VOLUME_NAME}\n"
    docker volume rm "${VOLUME_NAME}"
  fi
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
  local commit_hash=$(git rev-parse HEAD)
  echo "${commit_hash}"
}

function get_branch_name() {
  cd "${DIR}"
  local branch_name=$(git branch --show-current)
  echo "${branch_name}"
}

function create_commit_file() {
  local commit_hash="${1}"

  local MIGRATION_COMMIT_FILE_PATH="$(get_path_with_env "${GEN_MIGRATION_COMMIT_FILE_PATH}" "${ENV_NAME}")"

  rm -f -v "${MIGRATION_COMMIT_FILE_PATH}"
  touch "${MIGRATION_COMMIT_FILE_PATH}"

  echo "${commit_hash}" >> "${MIGRATION_COMMIT_FILE_PATH}"
  echo -e "Migration commit hash: ${commit_hash}"
}

function get_date_and_time() {
  local date_now=$(date "+%F_%H-%M-%S")
  echo "${date_now}"
}

function read_last_migration() {
  local date_now=$(date "+%F_%H-%M-%S")
  echo "${date_now}"
}

function update_global_state_vars() {
  LAST_MIGRATION_DATE=$(get_date_and_time)
  LAST_COMMIT_HASH=$(get_commit_hash)
  LAST_COMMIT_SHORT_HASH="${LAST_COMMIT_HASH:0:7}"
}

function get_last_migration_number() {
  local LAST_COMPLETED_MIGRATION_FILE_PATH="$(get_path_with_env "${GEN_LAST_COMPLETED_MIGRATION_FILE_PATH}" "${ENV_NAME}")"
  local last_migration_number=$(printf "%04d" $(jq -r ".lastCompletedMigration" "${LAST_COMPLETED_MIGRATION_FILE_PATH}"))
  echo "${last_migration_number}"
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
  *)
    file_name="unknown-${ETH_BC_NETWORK_ID}"
    ;;
  esac
  rm -f -v ".openzeppelin/${file_name}.json"
}

function prepare_migration_state_files_structure() {
  update_global_state_vars
  create_migration_logs_dir_files "${LAST_MIGRATION_DATE}" "${ENV_PROFILE}"
  create_commit_file "${LAST_COMMIT_HASH}"
}

function run_docker_compose() {
  cd "${DIR}"
  docker-compose -f docker-compose.yml --profile "${COMPOSE_PROFILE}" up -d --remove-orphans
}

function stop_docker_compose() {
  cd "${DIR}"
  echo -e "\n\e[32mStopping ipor protocol containers with \e[33m${COMPOSE_PROFILE} \e[32mprofile..\e[0m\n"
  docker-compose -f docker-compose.yml --profile "${COMPOSE_PROFILE}" rm -s -v -f
}

function rm_smart_contracts_migrations_state_file() {
  rm -f -v ".openzeppelin/unknown-${ETH_BC_NETWORK_ID}.json"
}

function clean_eth_blockchain() {
  cd "${DIR}"

  echo -e "\n\e[32mClean Ethereum blockchain...\e[0m\n"

  remove_container "${ETH_BC_CONTAINER}"
  remove_volume "${ETH_BC_DATA_VOLUME}"

  remove_container "${ETH_EXP_CONTAINER}"
  remove_container "${ETH_EXP_POSTGRES_CONTAINER}"
  remove_volume "${ETH_EXP_DATA_VOLUME}"

  rm_smart_contracts_migrations_state_file
}

function run_smart_contract_migrations() {
  cd "${DIR}"

  echo -e "\n\e[32mMigrate Smart Contracts to Ethereum blockchain...\e[0m\n"

  prepare_migration_state_files_structure

  npm run compile:truffle 2>&1| tee ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log"
  npm run export-abi
  export ETH_BC_NETWORK_NAME
  npm run migrate:truffle 2>&1| tee ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log"
}

function wait_for_eth_bc() {
  local RESULT=""
  for i in {1..20}; do
    if [[ $i == 20 ]]; then
      echo -e "ERROR: Container: ${ETH_BC_CONTAINER} still not ready after 60 seconds." 1>&2
      exit
    fi
    RESULT=$(curl -X POST -s --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' -H 'Content-Type: application/json' "${ETH_BC_URL}" | jq -r '.result.number') && echo ""
    if [[ $RESULT == 0x* ]]; then
      break
    fi
    echo -e "Wait next 3 seconds for Ethereum blockchain container: ${ETH_BC_CONTAINER}\n"
    sleep 3
  done
}

function clean_migration_files(){
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
  clean_migration_files

  prepare_migration_state_files_structure

  npm run compile:truffle 2>&1| tee ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log"
  npm run export-abi
  export ETH_BC_NETWORK_NAME
  npm run migrate:truffle-reset 2>&1| tee ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log"
}

function get_docker_volume_host_path() {
  local CONTAINER_NAME="${1}"
  local VOLUME_NAME="${2}"
  local VOLUME_HOST_PATH=$(docker inspect "${CONTAINER_NAME}" | jq -r '.[].Mounts[] | select(.Name=="'"${VOLUME_NAME}"'") | .Source')
  echo "${VOLUME_HOST_PATH}"
}

function dump_eth_blockchain_from_host() {
  cd "${DIR}"
  echo -e "\n\e[32mDump ethereum blockchain..\e[0m\n"

  local VOLUME_HOST_PATH=$(get_docker_volume_host_path "${ETH_BC_CONTAINER}" "${ETH_BC_DATA_VOLUME}")
  mkdir -p "${ETH_BC_DUMP_DIR}"
  echo "Need root access to ${VOLUME_HOST_PATH} directory to copy it. Please type sudo password."
  echo "${ROOT_PASSWORD}" | sudo -S tar -cvf "${ETH_BC_DUMP_PATH}" -C "${VOLUME_HOST_PATH}" ".ethereum"

  echo -e "\n\e[32mDump DONE\e[0m location: ${ETH_BC_DUMP_PATH}\n"
}

function dump_eth_blockchain_from_docker() {
  local ENV_NAME="${1}"
  local ENV_DIR=$(get_path_with_env "${ETH_BC_DUMP_CONFIG_DIR}" "${ENV_NAME}")

  cd "${DIR}"
  echo -e "\n\e[32mDump ethereum blockchain..\e[0m\n"

  echo -e "Remove old dump data from: ${ETH_BC_DUMP_DIR}/${ETH_DATA_DIR}\n"
  rm -f -v -R "${ETH_BC_DUMP_DIR}"
  mkdir -p "${ETH_BC_DUMP_DIR}"

  echo -e "Copy blockchain data from container: ${ETH_BC_CONTAINER}:/root\n"
  docker cp "${ETH_BC_CONTAINER}:/root/${ETH_DATA_DIR}/" "${ETH_BC_DUMP_DIR}/"

  cd "${ETH_BC_DUMP_DIR}"
  echo -e "Pack dump data into archive: ${ETH_BC_DUMP_PATH}\n"
  tar -cvf "${ETH_BC_DUMP_PATH}" "${ETH_DATA_DIR}"
  cp "${ETH_BC_DUMP_PATH}" "${ENV_DIR}/${ETH_BC_DUMP_FILE}"

  echo -e "\n\e[32mDump DONE\e[0m location: ${ETH_BC_DUMP_PATH}\n"
}

function get_path_with_env() {
  local SOURCE_PATH="${1}"
  local ENV_NAME="${2}"
  local TARGET_PATH=${SOURCE_PATH/\{ENV\}/$ENV_NAME}
  echo "${TARGET_PATH}"
}

function create_env_file() {
  local SRC_ENV_FILE="${1}"
  local ENV_VARIABLES_FILE="${2}"
  local TARGET_ENV_FILE="${3}"

  fill_j2_template "${SRC_ENV_FILE}" "${ENV_VARIABLES_FILE}" "${TARGET_ENV_FILE}"
}

function create_env_j2_variables_file() {
  local SOURCE_ENV_FILE="${1}"
  local TARGET_VARIABLES_FILE="${2}"
  local EXTRA_VARIABLES_FILE="${3}"
  local LINE=""
  local VALUE=""
  local NAME=""

  rm -f -v "${TARGET_VARIABLES_FILE}"
  grep <"${SOURCE_ENV_FILE}" -E -v "(^#.*|^$)" |
    while IFS= read -r LINE; do
      VALUE=${LINE#*=}
      NAME=${LINE%%=*}
      echo "${NAME,,}=${VALUE}" >>"${TARGET_VARIABLES_FILE}"
    done

  cat "${EXTRA_VARIABLES_FILE}" >>"${TARGET_VARIABLES_FILE}"
}

function fill_j2_template() {
  local TEMPLATE_FILE="${1}"
  local VARIABLES_FILE="${2}"
  local OUTPUT_FILE="${3}"

  j2 -f env "${TEMPLATE_FILE}" "${VARIABLES_FILE}" >"${OUTPUT_FILE}"
}

function set_value_in_env_config_file() {
  local VAR_NAME="${1}"
  local VAR_VALUE="$(echo $2 | sed 's/\//\\\//g' | sed 's/\./\\\./g')"
  local TARGET_ENV_FILE="${3}"

  echo "sed -i 's/${VAR_NAME}.*/${VAR_NAME}=${VAR_VALUE}/' '${TARGET_ENV_FILE}'"
  sed -i "s/${VAR_NAME}.*/${VAR_NAME}=${VAR_VALUE}/" "${TARGET_ENV_FILE}"
}

function replace_values_in_env_config_file() {
  local SOURCE_ENV_FILE="${1}"
  local TARGET_ENV_FILE="${2}"
  local LINE=""
  local VALUE=""
  local NAME=""

  grep <"${SOURCE_ENV_FILE}" -E -v "(^#.*|^$)" |
    while IFS= read -r LINE; do
      VALUE=${LINE#*=}
      NAME=${LINE%%=*}
      set_value_in_env_config_file "${NAME}" "${VALUE}" "${TARGET_ENV_FILE}"
    done
}

function prepare_env_config_file() {
  local ENV_NAME="${1}"
  local ENV_DIR=$(get_path_with_env "${ETH_BC_DUMP_CONFIG_DIR}" "${ENV_NAME}")
  local VARIABLES_FILE_PATH=$(get_path_with_env "${ENV_LOCAL_VARIABLES_FILE}" "${ENV_NAME}")

  create_env_file "${ENV_LOCAL_TEMPLATE_FILE}" "${ENV_CREDENTIALS_VARIABLES_FILE}" "${ENV_FILE}"
  replace_values_in_env_config_file "${VARIABLES_FILE_PATH}" "${ENV_FILE}"
  cp "${ENV_FILE}" "${ENV_DIR}/${ENV_FILE_NAME}"

  read_env_file "${ENV_FILE}"
}

function fill_j2_templates() {
  local ENV_NAME="${1}"
  local VARIABLES_PATH="$(get_path_with_env "${ETH_BC_GEN_VARIABLES_PATH}" "${ENV_NAME}")"

  fill_j2_template "${ETH_BC_GENESIS_J2_PATH}" "${VARIABLES_PATH}" "$(get_path_with_env "${ETH_BC_GEN_GENESIS_PATH}" "${ENV_NAME}")"
  fill_j2_template "${ETH_BC_CONFIG_J2_PATH}" "${VARIABLES_PATH}" "$(get_path_with_env "${ETH_BC_GEN_CONFIG_PATH}" "${ENV_NAME}")"
  fill_j2_template "${ETH_BC_KEY_PASSWORD_J2_PATH}" "${VARIABLES_PATH}" "$(get_path_with_env "${ETH_BC_GEN_KEY_PASSWORD_PATH}" "${ENV_NAME}")"
  fill_j2_template "${ETH_BC_MINER_KEY_J2_PATH}" "${VARIABLES_PATH}" "$(get_path_with_env "${ETH_BC_GEN_MINER_KEY_PATH}" "${ENV_NAME}")"

  # Create cockpit config file
  fill_j2_template "${IPOR_COCKPIT_ENV_CONFIG_J2_PATH}" "${VARIABLES_PATH}" "${IPOR_COCKPIT_GEN_ENV_CONFIG_PATH}"
}

function login_ecr() {
  echo "docker login: ${AWS_DOCKER_REGISTRY}"

  local WITH_PROFILE=$(get_aws_profile)

  aws ecr get-login-password ${WITH_PROFILE} --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_DOCKER_REGISTRY}"
}

function logout_ecr() {
  echo "docker logout: ${AWS_DOCKER_REGISTRY}"
  docker logout "${AWS_DOCKER_REGISTRY}"
}

function push_docker_image() {
  local CONTAINER_NAME="${1}"
  local TAG="${2}"

  if [ $CGI_PUBLISH_ENABLED = "true" ]; then
    echo "docker push ${CONTAINER_NAME}:${TAG}"
    docker push "${CONTAINER_NAME}:${TAG}"
  else
    echo "SKIP: docker push"
  fi
}

function pull_docker_image() {
  local CONTAINER_NAME="${1}"
  local TAG="${2}"

  echo "docker pull ${CONTAINER_NAME}:${TAG}"
  docker pull "${CONTAINER_NAME}:${TAG}"
}

function retag_docker_image() {
  local CONTAINER_NAME="${1}"
  local OLD_TAG="${2}"
  local NEW_TAG="${3}"

  echo "docker tag ${CONTAINER_NAME}:${OLD_TAG} ${CONTAINER_NAME}:${NEW_TAG}"
  docker tag "${CONTAINER_NAME}:${OLD_TAG}" "${CONTAINER_NAME}:${NEW_TAG}"
}

function build_geth_docker_image() {
  local DOCKERFILE_DIR="${1}"
  local CONTAINER_NAME="${2}"
  local TAG="${3}"

  cd "${DOCKERFILE_DIR}"
  echo -e "\n\e[32mBuild ${CONTAINER_NAME}:${TAG} docker\e[0m\n"
  docker build --no-cache -t "${CONTAINER_NAME}:${TAG}" \
    --build-arg ENV_PROFILE="${ENV_PROFILE}" \
    --build-arg TZ="${TZ}" \
    --build-arg ETH_BC_CORS="${ETH_BC_CORS}" \
    --build-arg ETH_BC_HOST_ADDRESS="${ETH_BC_HOST_ADDRESS}" \
    --build-arg ETH_BC_MINER_ADDRESS="${ETH_BC_MINER_ADDRESS}" \
    --build-arg ETH_BC_NETWORK_PORT="${ETH_BC_NETWORK_PORT}" \
    --build-arg ETH_BC_DATA_DIR="${ETH_BC_DATA_DIR}" \
    --build-arg ETH_BC_GENESIS_BLOCK_FILE="${ETH_BC_GENESIS_BLOCK_FILE}" \
    --build-arg ETH_BC_CONFIG_FILE="${ETH_BC_CONFIG_FILE}" \
    --build-arg ETH_BC_MINER_KEY_PASSWORD_FILE="${ETH_BC_MINER_KEY_PASSWORD_FILE}" \
    --build-arg ETH_BC_MINER_KEY_FILE="${ETH_BC_MINER_KEY_FILE}" \
    --build-arg ETH_BC_MINER_THREADS="${ETH_BC_MINER_THREADS}" \
    --build-arg ETH_BC_NETWORK_ID="${ETH_BC_NETWORK_ID}" \
    --build-arg ETH_BC_BLOCK_PERIOD="${ETH_BC_BLOCK_PERIOD}" \
    --build-arg ETH_BC_BLOCK_GAS_LIMIT="${ETH_BC_BLOCK_GAS_LIMIT}" \
    --build-arg ETH_BC_NODE_MODE="${ETH_BC_NODE_MODE}" \
    --build-arg ETH_BC_NODE_NAME="${ETH_BC_NODE_NAME}" \
    --build-arg ETH_BC_HTTP_API="${ETH_BC_HTTP_API}" \
    --build-arg ETH_BC_WS_API="${ETH_BC_WS_API}" \
    --build-arg ETH_BC_VERBOSITY="${ETH_BC_VERBOSITY}" \
    --build-arg ETH_BC_VMODULE_VERBOSITY="${ETH_BC_VMODULE_VERBOSITY}" \
    --build-arg ETH_BC_DUMP_DIR="${ETH_BC_DUMP_DIR}" \
    --build-arg ETH_BC_INIT_GENESIS_BLOCK="${ETH_BC_INIT_GENESIS_BLOCK}" \
    .
}

function build_docker_image() {
  local DOCKERFILE_DIR="${1}"
  local CONTAINER_NAME="${2}"
  local TAG="${3}"

  cd "${DOCKERFILE_DIR}"
  echo -e "\n\e[32mBuild ${CONTAINER_NAME}:${TAG} docker\e[0m\n"
  docker build --no-cache -t "${CONTAINER_NAME}:${TAG}" .
}

function create_env_config() {
  local ENV_NAME="${1}"
  local ALL_VARIABLES_FILE_PATH=$(get_path_with_env "${ETH_BC_GEN_VARIABLES_PATH}" "${ENV_NAME}")

  # Create and read .env file
  prepare_env_config_file "${ENV_NAME}"

  # Configure env variables file
  create_env_j2_variables_file "${ENV_FILE}" "${ALL_VARIABLES_FILE_PATH}" "${ENV_CREDENTIALS_VARIABLES_FILE}"

  # Create geth config files
  fill_j2_templates "${ENV_NAME}"
}

function migrate_and_dump() {
  local ENV_NAME="${1}"

  # Remove current docker and volumes
  clean_eth_blockchain

  # Run containers
  run_docker_compose

  # Wait for eth blockchain container
  wait_for_eth_bc

  # Run migrations
  run_clean_smart_contract_migrations

  # Dump volume
  dump_eth_blockchain_from_docker "${ENV_NAME}"
}

function copy_smart_contract_addresses_file() {
  local ENV_NAME="${1}"

  cd "${DIR}"
  create_env_config_file
  echo "Copy: ${ENV_CONFIG_FILE_DEST} into: $(get_path_with_env "${ETH_BC_GEN_ENV_CONFIG_FILE_PATH}" "${ENV_NAME}")"
  cp "${ENV_CONFIG_FILE_DEST}" "$(get_path_with_env "${ETH_BC_GEN_ENV_CONFIG_FILE_PATH}" "${ENV_NAME}")"
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

function clean_env_files() {
  local ENV_NAME="${1}"

  echo "Clean env files in dir: $(get_path_with_env "${ETH_BC_GEN_ENV_DUMP_CONFIG_DIR}" "${ENV_NAME}")"

  rm -f -v "$(get_path_with_env "${ETH_BC_DUMP_CONFIG_DIR}/${ENV_FILE_NAME}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_VARIABLES_PATH}" "${ENV_NAME}")"

  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_GENESIS_PATH}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_CONFIG_PATH}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_KEY_PASSWORD_PATH}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_MINER_KEY_PATH}" "${ENV_NAME}")"

  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_ENV_CONFIG_FILE_PATH}" "${ENV_NAME}")"
  rm -f -v "$(get_path_with_env "${ETH_BC_GEN_ENV_CONTRACTS_FILE_PATH}" "${ENV_NAME}")"
  rm -R -f -v "$(get_path_with_env "${ETH_BC_GEN_ENV_DUMP_CONFIG_DIR}${IPOR_MIGRATION_STATE_DIR}" "${ENV_NAME}")"
}

function copy_env_files() {
  local ENV_NAME="${1}"

  copy_smart_contract_addresses_file "${ENV_NAME}"
  copy_smart_contract_json_files "${ENV_NAME}"
  copy_ipor_migrations_dir "${ENV_NAME}"
}

function build_and_push_docker_images() {
  local ENV_NAME="${1}"
  local COMMIT_HASH="${2}"

  # Login into ECR
  login_ecr

  # Build geth docker image
  build_geth_docker_image "${ETH_BC_DOCKERFILE_PATH}" "${AWS_DOCKER_REGISTRY}/${ETH_BC_IMAGE_NAME}" "${ENV_NAME}-${COMMIT_HASH}"

  # Push geth docker image
  push_docker_image "${AWS_DOCKER_REGISTRY}/${ETH_BC_IMAGE_NAME}" "${ENV_NAME}-${COMMIT_HASH}"

  # Build cockpit docker image
  build_docker_image "${IPOR_COCKPIT_DOCKERFILE_PATH}" "${AWS_DOCKER_REGISTRY}/${IPOR_COCKPIT_IMAGE_NAME}" "${ENV_NAME}-${COMMIT_HASH}"

  # Push cockpit docker image
  push_docker_image "${AWS_DOCKER_REGISTRY}/${IPOR_COCKPIT_IMAGE_NAME}" "${ENV_NAME}-${COMMIT_HASH}"

  # Logout from ECR
  logout_ecr
}

function retag_and_push_docker_image() {
  local CONTAINER_NAME="${1}"
  local OLD_TAG="${2}"
  local NEW_TAG="${3}"

  pull_docker_image "${CONTAINER_NAME}" "${OLD_TAG}"
  retag_docker_image "${CONTAINER_NAME}" "${OLD_TAG}" "${NEW_TAG}"
  push_docker_image "${CONTAINER_NAME}" "${NEW_TAG}"
}

function tag_and_push_docker_images() {
  local ENV_NAME="${1}"
  local COMMIT_HASH="${2}"
  local BRANCH_NAME="${3}"

  echo "Rename docker tag from: ${ENV_NAME}-${COMMIT_HASH} into: ${ENV_NAME}-${BRANCH_NAME}"

  # Push docker image
  retag_and_push_docker_image "${AWS_DOCKER_REGISTRY}/${ETH_BC_IMAGE_NAME}" "${ENV_NAME}-${COMMIT_HASH}" "${ENV_NAME}-${BRANCH_NAME}"

  # Push cockpit docker image
  retag_and_push_docker_image "${AWS_DOCKER_REGISTRY}/${IPOR_COCKPIT_IMAGE_NAME}" "${ENV_NAME}-${COMMIT_HASH}" "${ENV_NAME}-${BRANCH_NAME}"
}

function create_geth_image() {
  local ENV_NAME="${1}"
  local COMMIT_HASH="${2}"

  clean_env_files "${ENV_NAME}"

  create_env_config "${ENV_NAME}"

  migrate_and_dump "${ENV_NAME}"

  copy_env_files "${ENV_NAME}"

  build_and_push_docker_images "${ENV_NAME}" "${COMMIT_HASH}"
}

function create_migrated_geth_image() {
  local ENV_NAME="${1}"
  local COMMIT_HASH="${2}"

  clean_env_files "${ENV_NAME}"

  create_env_config "${ENV_NAME}"

  copy_env_files "${ENV_NAME}"

  build_and_push_docker_images "${ENV_NAME}" "${COMMIT_HASH}"
}

################################### COMMANDS ###################################


if [ $IS_DOCKER_LOGIN = "YES" ]; then
  echo -e "\n\e[32mDocker login into AWS registry\e[0m\n"
  login_ecr
fi

if [ $IS_BUILD_DOCKER = "YES" ]; then
  cd "${DIR}"
  npm install

  echo -e "\n\e[32mBuild IPOR cockpit docker...\e[0m\n"
  build_docker_image "${IPOR_COCKPIT_DOCKERFILE_PATH}" "${IPOR_COCKPIT_IMAGE_NAME}" "latest"

  cd "${CONTAINERS_DIR}/nginx-eth-bc"
  echo -e "\n\e[32mBuild nginx-eth-bc docker...\e[0m\n"
  build_docker_image "${CONTAINERS_DIR}/nginx-eth-bc" "ipor-nginx-eth-bc" "latest"
fi

if [ $IS_STOP = "YES" ]; then
  stop_docker_compose
fi

if [ $IS_RUN = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mStarting ipor protocol containers with \e[33m${COMPOSE_PROFILE} \e[32mprofile..\e[0m\n"
  run_docker_compose
fi

if [ $IS_CLEAN_BC = "YES" ]; then
  clean_eth_blockchain

  echo -e "Start cleaned containers: ${ETH_BC_CONTAINER}/${ETH_EXP_CONTAINER}/${ETH_EXP_POSTGRES_CONTAINER} with \e[32m${COMPOSE_PROFILE}\e[0m profile..\n"
  run_docker_compose
fi

if [ $IS_MIGRATE_SC = "YES" ]; then
  run_smart_contract_migrations
fi

if [ $IS_MIGRATE_WITH_CLEAN_SC = "YES" ]; then
  run_clean_smart_contract_migrations
fi

if [ $COMMIT_MIGRATION_STATE = "YES" ]; then

  cd "${DIR}"
  LAST_MIGRATION_NUMBER=$(get_last_migration_number)

  profile_dir="${MIGRATION_STATE_REPO_DIR}/${ENV_PROFILE}"
  migration_date_dir="${MIGRATION_STATE_REPO_DIR}/${ENV_PROFILE}/migrations/${LAST_MIGRATION_NUMBER}_${LAST_COMMIT_SHORT_HASH}_${LAST_MIGRATION_DATE}"
  actual_state_dir="${profile_dir}/actual_state"

  echo "Copy migration state to: ${migration_date_dir}"

  cd "${MIGRATION_STATE_REPO_DIR}"
  echo "Git pull: ${MIGRATION_STATE_REPO}"
  git pull

  cd "${DIR}"
  mkdir -p "${actual_state_dir}"
  mkdir -p "${migration_date_dir}/logs"

  create_contracts_zip

  cp -R ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log" "${migration_date_dir}/logs"
  cp -R ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log" "${migration_date_dir}/logs"
  cp -R "${IPOR_MIGRATION_STATE_DIR}/" "${migration_date_dir}"
  cp -R "${IPOR_MIGRATION_STATE_DIR}/" "${actual_state_dir}"
  cp -R .openzeppelin/ "${migration_date_dir}"
  cp -R .openzeppelin/ "${actual_state_dir}"
  cp "${ENV_CONTRACTS_ZIP_DEST}" "${migration_date_dir}/${ENV_CONTRACTS_FILE_NAME}"

  cd "${MIGRATION_STATE_REPO_DIR}"
  echo "Git add: ${MIGRATION_STATE_REPO}"
  git add .

  echo "Git commit: ${MIGRATION_STATE_REPO} | with msg: Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE}"
  git commit -m "Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE}"

  echo "Git push: ${MIGRATION_STATE_REPO}"
  git push
  cd "${DIR}"
fi

if [ $IS_PUBLISH_ARTIFACTS = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mPublish artifacts to S3 bucket: ${ENV_CONFIG_BUCKET}/${ENV_PROFILE}\e[0m\n"

  create_env_config_file
  create_contracts_zip

  put_file_to_bucket "${ENV_CONTRACTS_ZIP_DEST}" "${ENV_CONTRACTS_ZIP_RMT}"
  put_file_to_bucket "${ENV_CONFIG_FILE_DEST}" "${ENV_CONFIG_FILE_RMT}"
fi

if [ $IS_NGINX_ETH_BC_RESTART = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mRestart NGINX Ethereum blockchain...\e[0m\n"

  EXISTS=$(docker ps -a -q -f name="${NGINX_ETH_BC_CONTAINER}")
  if [ -n "$EXISTS" ]; then
    echo -e "Remove container: ${NGINX_ETH_BC_CONTAINER}\n"
    docker stop "${NGINX_ETH_BC_CONTAINER}"
    docker rm -v -f "${NGINX_ETH_BC_CONTAINER}"
  fi

  echo -e "Start cleaned container: ${NGINX_ETH_BC_CONTAINER} with \e[33m${COMPOSE_PROFILE}\e[0m profile..\n"
  run_docker_compose
fi

if [ $IS_UPDATE_COCKPIT = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mUpdate IPOR cockpit..\e[0m\n"

  remove_container "${IPOR_COCKPIT_IMAGE_NAME}"

  echo -e "Start cleaned container: ${IPOR_COCKPIT_IMAGE_NAME} with \e[33m${COMPOSE_PROFILE}\e[0m profile..\n"
  run_docker_compose
fi

if [ $IS_DUMP_ETH_BLOCKCHAIN = "YES" ]; then
  dump_eth_blockchain_from_docker "localhost"
fi

if [ $IS_DOWNLOAD_DEPLOYED_SMART_CONTRACTS = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mDownload deployed smart contracts zip archive..\e[0m\n"

  WITH_PROFILE=$(get_aws_profile)

  aws s3 cp "s3://${ENV_CONFIG_BUCKET}/${ENV_CONTRACTS_ZIP_RMT}" "${ENV_CONTRACTS_ZIP_DEST}" ${WITH_PROFILE}

  unzip -o "${ENV_CONTRACTS_ZIP_DEST}" -d "${ENV_CONTRACTS_DIR}"
fi

if [ $IS_CREATE_GETH_IMAGE = "YES" ]; then

  echo -e "\n\e[32mCreate geth docker images\e[0m\n"

  CGI_COMMIT_HASH=$(get_commit_hash)

  if [ $CGI_IMAGE_TYPE = "${ETH_BC_ITF_TAG_NAME}" ]; then
    create_geth_image "${ETH_BC_ITF_TAG_NAME}" "${CGI_COMMIT_HASH}"
  elif [ $CGI_IMAGE_TYPE = "${ETH_BC_BLOCK_PER_TRANSACTION_TAG_NAME}/${ETH_BC_BLOCK_PER_INTERVAL_TAG_NAME}" ]; then
    create_geth_image "${ETH_BC_BLOCK_PER_TRANSACTION_TAG_NAME}" "${CGI_COMMIT_HASH}"
    create_migrated_geth_image "${ETH_BC_BLOCK_PER_INTERVAL_TAG_NAME}" "${CGI_COMMIT_HASH}"
  else
    echo "ERROR: Unknown first parameter in 'create-geth-image' command: '${CGI_IMAGE_TYPE}' " \
    "Allowed options: '${ETH_BC_ITF_TAG_NAME}' or '${ETH_BC_BLOCK_PER_TRANSACTION_TAG_NAME}/${ETH_BC_BLOCK_PER_INTERVAL_TAG_NAME}'"
    exit 1
  fi

fi

if [ $IS_RETAG_GETH_IMAGE = "YES" ]; then

  echo -e "\n\e[32mRename geth docker images tags\e[0m\n"

  CGI_PUBLISH_ENABLED="true"
  CGI_COMMIT_HASH=$(get_commit_hash)
  CGI_BRANCH_NAME=$(get_branch_name)

  login_ecr

  tag_and_push_docker_images "${ETH_BC_ITF_TAG_NAME}" "${CGI_COMMIT_HASH}" "${CGI_BRANCH_NAME}"
  tag_and_push_docker_images "${ETH_BC_BLOCK_PER_TRANSACTION_TAG_NAME}" "${CGI_COMMIT_HASH}" "${CGI_BRANCH_NAME}"
  tag_and_push_docker_images "${ETH_BC_BLOCK_PER_INTERVAL_TAG_NAME}" "${CGI_COMMIT_HASH}" "${CGI_BRANCH_NAME}"

  logout_ecr
fi


if [ $IS_HELP = "YES" ]; then
  echo -e "usage: \e[32m./run.sh\e[0m [cmd1] [cmd2] [cmd3]"
  echo -e ""
  echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
  echo -e "   \e[36mdocker-login\e[0m|\e[36mdl\e[0m     Docker login into AWS ECR"
  echo -e "   \e[36mbuild\e[0m|\e[36mb\e[0m             Build IPOR dockers"
  echo -e "   \e[36mrun\e[0m|\e[36mr\e[0m               Run / restart IPOR dockers"
  echo -e "   \e[36mstop\e[0m|\e[36ms\e[0m              Stop IPOR dockers"
  echo -e "   \e[36mmigrate\e[0m|\e[36mm\e[0m           Compile and migrate Smart Contracts to blockchain"
  echo -e "   \e[36mmigrationlogs|\e[36mmlogs\e[0m Commit logs after migration"
  echo -e "   \e[36mmigrateclean\e[0m|\e[36mmc\e[0m     Compile and migrate with clean Smart Contracts to blockchain"
  echo -e "   \e[36mpublish\e[0m|\e[36mp\e[0m           Publish build artifacts to S3 bucket"
  echo -e "   \e[36mclean\e[0m|\e[36mc\e[0m             Clean Ethereum blockchain"
  echo -e "   \e[36mnginx\e[0m|\e[36mn\e[0m             Restart nginx Ethereum blockchain container"
  echo -e "   \e[36mupdate-cockpit\e[0m|\e[36muc\e[0m        Update IPOR cockpit container"
  echo -e "   \e[36mdump-eth-blockchain\e[0m|\e[36mdeb\e[0m  Dump Ethereum blockchain"
  echo -e "   \e[36mretag-geth-image\e[0m|\e[36mrgi\e[0m   Rename geth docker images tags with tag from branch name"
  echo -e "   \e[36mcreate-geth-image\e[0m|\e[36mcgi {image_type} {publish_enabled}\e[0m  Create geth docker image"
  echo -e "   \e[36mdownload-deployed-smart-contracts\e[0m|\e[36mddsc\e[0m             Download deployed smart contracts"
  echo -e "   \e[36mhelp\e[0m|\e[36mh\e[0m|\e[36m?\e[0m            Show help"
  echo -e "   \e[34mwithout any command\e[0m - the same as Run"
  echo -e ""
  exit 0
fi
