#!/usr/bin/env bash

set -e -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENV_FILE="${DIR}/.env"

if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
  echo -e "\n\e[32m${ENV_FILE} file was read\e[0m\n"
fi

ENV_CONFIG_BUCKET="ipor-env"

ENV_CONFIG_FILE_SRC="smart-contract-addresses.yaml.j2"
ENV_CONFIG_FILE_DEST="smart-contract-addresses.yaml"
ENV_CONFIG_FILE_RMT="${ENV_PROFILE}/${ENV_CONFIG_FILE_DEST}"

ENV_CONTRACTS_FILE_NAME="contracts.zip"
ENV_CONTRACTS_ROOT_DIR="app/src"
ENV_CONTRACTS_DIR="${ENV_CONTRACTS_ROOT_DIR}/contracts"
ENV_CONTRACTS_ZIP_DEST="${ENV_CONTRACTS_ROOT_DIR}/${ENV_CONTRACTS_FILE_NAME}"
ENV_CONTRACTS_ZIP_RMT="${ENV_PROFILE}/${ENV_CONTRACTS_FILE_NAME}"

ETH_BC_CONTAINER="ipor-protocol-eth-bc"
ETH_EXP_CONTAINER="ipor-protocol-eth-explorer"
ETH_EXP_POSTGRES_CONTAINER="ipor-protocol-eth-exp-postgres"
DEV_TOOL_CONTAINER="ipor-protocol-milton-tool"

ETH_BC_DATA_VOLUME="ipor-protocol-eth-bc-data"
ETH_EXP_DATA_VOLUME="ipor-protocol-eth-exp-postgres-data"

NGINX_ETH_BC_CONTAINER="ipor-protocol-nginx-eth-bc"

AWS_REGION="eu-central-1"

GET_IP_TOKEN_METHOD_SIGNATURE="0xf64de4ed"

SC_MIGRATION_STATE_REPO_DIR="${DIR}/../${SC_MIGRATION_STATE_REPO}"
MIGRATION_COMMIT_FILE_PATH=".ipor/${ENV_PROFILE}-${ETH_BC_NETWORK_NAME}-migration-commit.txt"
LAST_COMPLETED_MIGRATION_FILE_PATH=".ipor/${ENV_PROFILE}-${ETH_BC_NETWORK_NAME}-last-completed-migration.json"

IS_MIGRATE_SC="NO"
IS_MIGRATE_WITH_CLEAN_SC="NO"
IS_BUILD_DOCKER="NO"
IS_CLEAN_BC="NO"
IS_RUN="NO"
IS_STOP="NO"
IS_HELP="NO"
IS_PUBLISH_ARTIFACTS="NO"
IS_NGINX_ETH_BC_RESTART="NO"
IS_UPDATE_DEV_TOOL="NO"
COMMIT_MIGRATION_STATE="NO"
IS_DOWNLOAD_DEPLOYED_SMART_CONTRACTS="NO"

LAST_MIGRATION_DATE=""
LAST_COMMIT_HASH=""
LAST_COMMIT_SHORT_HASH=""
LAST_MIGRATION_NUMBER=""

if [ $# -eq 0 ]; then
    IS_RUN="YES"
fi

while test $# -gt 0
do
    case "$1" in
        migrate|m)
            IS_MIGRATE_SC="YES"
        ;;
        migrateclean|mc)
            IS_MIGRATE_WITH_CLEAN_SC="YES"
        ;;
        migrationlogs|mlogs)
            COMMIT_MIGRATION_STATE="YES"
        ;;
        build|b)
            IS_BUILD_DOCKER="YES"
        ;;
        run|r)
            IS_RUN="YES"
            IS_STOP="YES"
        ;;
        stop|s)
            IS_STOP="YES"
        ;;
        publish|p)
            IS_PUBLISH_ARTIFACTS="YES"
        ;;
        clean|c)
            IS_CLEAN_BC="YES"
        ;;
        nginx|n)
            IS_NGINX_ETH_BC_RESTART="YES"
        ;;
        update-dev-tool|udt)
            IS_UPDATE_DEV_TOOL="YES"
        ;;
        download-deployed-smart-contracts|ddsc)
            IS_DOWNLOAD_DEPLOYED_SMART_CONTRACTS="YES"
        ;;
        help|h|?)
            IS_HELP="YES"
        ;;
        *)
            echo -e "\e[33mWARNING!\e[0m ${1} - command not found"
        ;;
    esac
    shift
done


################################### FUNCTIONS ###################################

function set_smart_contract_address_in_env_config_file(){
  local VAR_NAME="${1}"
  local VAR_VALUE="${2}"
  sed -i "s/${VAR_NAME}.*/${VAR_NAME}: \"${VAR_VALUE}\"/" "${ENV_CONFIG_FILE_DEST}"
}

function get_smart_contract_address_from_json_file(){
  local FILE_NAME="${1}"
  local VAR_VALUE=$(jq -r '.networks[].address' "${ENV_CONTRACTS_DIR}/${FILE_NAME}")
  echo "${VAR_VALUE}"
}

function set_smart_contract_address_from_json_file(){
  local FILE_NAME="${1}"
  local VAR_NAME="${2}"
  local VAR_VALUE=$(get_smart_contract_address_from_json_file "${FILE_NAME}")
  set_smart_contract_address_in_env_config_file "${VAR_NAME}" "${VAR_VALUE}"
  echo "${VAR_VALUE}"
}

function call_smart_contract_method(){
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

function get_smart_contract_address_from_eth_method(){
  local SMART_CONTRACT_ADDRESS="${1}"
  local METHOD_SIGNATURE="${2}"

  local RESULT=$(call_smart_contract_method "${SMART_CONTRACT_ADDRESS}" "${METHOD_SIGNATURE}")

  local RESULT_ADDRESS=$(echo "${RESULT}" | jq -r ".result")
  echo "0x${RESULT_ADDRESS:(-40)}"
}

function set_smart_contract_address_from_eth_method(){
  local SMART_CONTRACT_ADDRESS="${1}"
  local METHOD_SIGNATURE="${2}"
  local VAR_NAME="${3}"

  local VAR_VALUE=$(get_smart_contract_address_from_eth_method "${SMART_CONTRACT_ADDRESS}" "${METHOD_SIGNATURE}")
  set_smart_contract_address_in_env_config_file "${VAR_NAME}" "${VAR_VALUE}"
  echo "${VAR_VALUE}"
}

function create_env_config_file(){
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
  RESULT=$(set_smart_contract_address_from_json_file "ItfDataProvider.json" "itf_data_provider_address")


  echo -e "${ENV_CONFIG_FILE_DEST} file was created"
}

function create_contracts_zip(){
  if [ -f "${ENV_CONTRACTS_ZIP_DEST}" ]; then
    rm "${ENV_CONTRACTS_ZIP_DEST}"
  fi
  zip -r -j -q "${ENV_CONTRACTS_ZIP_DEST}" "${ENV_CONTRACTS_DIR}"
  echo -e "${ENV_CONTRACTS_ZIP_DEST} file was created"
}

function put_file_to_bucket(){
  local FILE_NAME="${1}"
  local FILE_KEY="${2}"

  export AWS_ACCESS_KEY_ID="${IPOR_ENV_ADMIN_AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${IPOR_ENV_ADMIN_AWS_SECRET_ACCESS_KEY}"

  aws s3api put-object --bucket "${ENV_CONFIG_BUCKET}" --key "${FILE_KEY}" --body "${FILE_NAME}" --region "${AWS_REGION}"
  echo -e "${FILE_KEY} file was published"
}

function remove_container(){
  local CONTAINER_NAME="${1}"
  local EXISTS=$(docker ps -a -q -f name="${CONTAINER_NAME}")
  if [ -n "$EXISTS" ]; then
      echo -e "Remove container: ${CONTAINER_NAME}\n"
      docker stop "${CONTAINER_NAME}"
      docker rm -v -f "${CONTAINER_NAME}"
  fi
}

function remove_volume(){
  local VOLUME_NAME="${1}"
  local EXISTS=$(docker volume ls -q -f name="${VOLUME_NAME}")
  if [ -n "$EXISTS" ]; then
      echo -e "Remove volume: ${VOLUME_NAME}\n"
      docker volume rm "${VOLUME_NAME}"
  fi
}

function create_migration_logs_dir_files(){
  local date_now="${1}"
  local env_name="${2}"

  cd "${DIR}"
  mkdir -p .ipor/
  mkdir -p ".logs/${env_name}/compile/"
  mkdir -p ".logs/${env_name}/migrate/"

  touch ".logs/${env_name}/compile/${date_now}_compile.log"
  touch ".logs/${env_name}/migrate/${date_now}_migrate.log"
}

function get_commit_hash(){
  cd "${DIR}"
  local commit_hash=$(git rev-parse HEAD)
  echo "${commit_hash}"
}

function create_commit_file(){
  local commit_hash="${1}"

  rm -f "${MIGRATION_COMMIT_FILE_PATH}"
  touch "${MIGRATION_COMMIT_FILE_PATH}"

  echo "${commit_hash}" >> "${MIGRATION_COMMIT_FILE_PATH}"
  echo -e "Migration commit hash: ${commit_hash}"
}

function get_date_and_time(){
  local date_now=$(date "+%F_%H-%M-%S")
  echo "${date_now}"
}

function read_last_migration(){
  local date_now=$(date "+%F_%H-%M-%S")
  echo "${date_now}"
}

function update_global_state_vars(){
  LAST_MIGRATION_DATE=$(get_date_and_time)
  LAST_COMMIT_HASH=$(get_commit_hash)
  LAST_COMMIT_SHORT_HASH="${LAST_COMMIT_HASH:0:7}"
}

function get_last_migration_number(){
  local last_migration_number=$(printf "%04d" $(jq -r ".lastCompletedMigration" "${LAST_COMPLETED_MIGRATION_FILE_PATH}"))
  echo "${last_migration_number}"
}

function clean_openzeppelin_migration_file(){
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
  rm -f ".openzeppelin/${file_name}.json"
}

function prepare_migration_state_files_structure(){
  update_global_state_vars
  create_migration_logs_dir_files "${LAST_MIGRATION_DATE}" "${ENV_PROFILE}"
  create_commit_file "${LAST_COMMIT_HASH}"
}

################################### COMMANDS ###################################

if [ $IS_BUILD_DOCKER = "YES" ]; then


  cd "${DIR}"  
  npm install

  cd "${DIR}/app"
  echo -e "\n\e[32mBuild Milton Tool docker...\e[0m\n"

  docker build -t io.ipor/ipor-protocol-milton-tool .

  cd "${DIR}/containers/nginx-eth-bc"
  echo -e "\n\e[32mBuild nginx-eth-bc docker...\e[0m\n"

  docker build -t io.ipor/nginx-eth-bc:latest .
fi

if [ $IS_STOP = "YES" ]; then
  cd "${DIR}"
  echo -e "\n\e[32mStopping ipor protocol containers with \e[33m${COMPOSE_PROFILE} \e[32mprofile..\e[0m\n"
  docker-compose -f docker-compose.yml --profile ${COMPOSE_PROFILE} rm -s -v -f
fi

if [ $IS_RUN = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mStarting ipor protocol containers with \e[33m${COMPOSE_PROFILE} \e[32mprofile..\e[0m\n"
  docker-compose -f docker-compose.yml --profile ${COMPOSE_PROFILE} up -d --remove-orphans
fi

if [ $IS_CLEAN_BC = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mClean Ethereum blockchain...\e[0m\n"

  remove_container "${ETH_BC_CONTAINER}"
  remove_volume "${ETH_BC_DATA_VOLUME}"

  remove_container "${ETH_EXP_CONTAINER}"
  remove_container "${ETH_EXP_POSTGRES_CONTAINER}"
  remove_volume "${ETH_EXP_DATA_VOLUME}"

  echo -e "Start cleaned containers: ${ETH_BC_CONTAINER}/${ETH_EXP_CONTAINER}/${ETH_EXP_POSTGRES_CONTAINER} with \e[32m${COMPOSE_PROFILE}\e[0m profile..\n"
  docker-compose -f docker-compose.yml --profile ${COMPOSE_PROFILE} up -d

  rm ".openzeppelin/unknown-${ETH_BC_NETWORK_ID}.json"
fi

if [ $IS_MIGRATE_SC = "YES" ]; then
  echo -e "\n\e[32mMigrate Smart Contracts to Ethereum blockchain...\e[0m\n"

  prepare_migration_state_files_structure

  cd "${DIR}"
  npm run compile:truffle 2>&1| tee ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log"
  npm run export-abi
  export ETH_BC_NETWORK_NAME
  npm run migrate:truffle 2>&1| tee ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log"
fi

if [ $IS_MIGRATE_WITH_CLEAN_SC = "YES" ]; then
  echo -e "\n\e[32mMigrate with clean Smart Contracts to Ethereum blockchain...\e[0m\n"

  clean_openzeppelin_migration_file
  rm -rf app/src/contracts/

  prepare_migration_state_files_structure

  cd "${DIR}"
  npm run compile:truffle 2>&1| tee ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log"
  npm run export-abi
  export ETH_BC_NETWORK_NAME
  npm run migrate:truffle-reset 2>&1| tee ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log"
fi

if [ $COMMIT_MIGRATION_STATE = "YES" ]; then

  cd "${DIR}"
  LAST_MIGRATION_NUMBER=$(get_last_migration_number)

  profile_dir="${SC_MIGRATION_STATE_REPO_DIR}/${ENV_PROFILE}"
  migration_date_dir="${SC_MIGRATION_STATE_REPO_DIR}/${ENV_PROFILE}/migrations/${LAST_MIGRATION_NUMBER}_${LAST_COMMIT_SHORT_HASH}_${LAST_MIGRATION_DATE}"
  actual_state_dir="${profile_dir}/actual_state"

  echo "Copy migration state to: ${migration_date_dir}"

  cd "${SC_MIGRATION_STATE_REPO_DIR}"
  echo "Git pull: ${SC_MIGRATION_STATE_REPO}"
  git pull

  cd "${DIR}"
  mkdir -p "${actual_state_dir}"
  mkdir -p "${migration_date_dir}/logs"

  create_contracts_zip

  cp -R ".logs/${ENV_PROFILE}/compile/${LAST_MIGRATION_DATE}_compile.log" "${migration_date_dir}/logs"
  cp -R ".logs/${ENV_PROFILE}/migrate/${LAST_MIGRATION_DATE}_migrate.log" "${migration_date_dir}/logs"
  cp -R .ipor/ "${migration_date_dir}"
  cp -R .ipor/ "${actual_state_dir}"
  cp -R .openzeppelin/ "${migration_date_dir}"
  cp -R .openzeppelin/ "${actual_state_dir}"
  cp "${ENV_CONTRACTS_ZIP_DEST}" "${migration_date_dir}/${ENV_CONTRACTS_FILE_NAME}"

  cd "${SC_MIGRATION_STATE_REPO_DIR}"
  echo "Git add: ${SC_MIGRATION_STATE_REPO}"
  git add .

  echo "Git commit: ${SC_MIGRATION_STATE_REPO} | with msg: Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE}"
  git commit -m "Migration - ${ENV_PROFILE} - ${LAST_MIGRATION_DATE}"

  echo "Git push: ${SC_MIGRATION_STATE_REPO}"
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
  docker-compose -f docker-compose.yml --profile ${COMPOSE_PROFILE} up -d
fi


if [ $IS_UPDATE_DEV_TOOL = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mUpdate dev-tool..\e[0m\n"

  remove_container "${DEV_TOOL_CONTAINER}"

  echo -e "Start cleaned container: ${DEV_TOOL_CONTAINER} with \e[33m${COMPOSE_PROFILE}\e[0m profile..\n"
  docker-compose -f docker-compose.yml --profile ${COMPOSE_PROFILE} up -d
fi


if [ $IS_DOWNLOAD_DEPLOYED_SMART_CONTRACTS = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mDownload deployed smart contracts zip archive..\e[0m\n"

  IPOR_ENV_USER_AWS_ACCESS_KEY_ID="${IPOR_ENV_USER_AWS_ACCESS_KEY_ID:-$IPOR_ENV_ADMIN_AWS_ACCESS_KEY_ID}"
  IPOR_ENV_USER_AWS_SECRET_ACCESS_KEY="${IPOR_ENV_USER_AWS_SECRET_ACCESS_KEY:-$IPOR_ENV_ADMIN_AWS_SECRET_ACCESS_KEY}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$IPOR_ENV_USER_AWS_ACCESS_KEY_ID}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-$IPOR_ENV_USER_AWS_SECRET_ACCESS_KEY}"

  aws s3 cp "s3://${ENV_CONFIG_BUCKET}/${ENV_CONTRACTS_ZIP_RMT}" "${ENV_CONTRACTS_ZIP_DEST}"

  unzip -o "${ENV_CONTRACTS_ZIP_DEST}" -d "${ENV_CONTRACTS_DIR}"
fi


if [ $IS_HELP = "YES" ]; then
    echo -e "usage: \e[32m./run.sh\e[0m [cmd1] [cmd2] [cmd3]"
    echo -e ""
    echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
    echo -e "   \e[36mbuild\e[0m|\e[36mb\e[0m             Build IPOR dockers"
    echo -e "   \e[36mrun\e[0m|\e[36mr\e[0m               Run / restart IPOR dockers"
    echo -e "   \e[36mstop\e[0m|\e[36ms\e[0m              Stop IPOR dockers"
    echo -e "   \e[36mmigrate\e[0m|\e[36mm\e[0m           Compile and migrate Smart Contracts to blockchain"
    echo -e "   \e[36mmigrationlogs|\e[36mmlogs\e[0m Commit logs after migration"
    echo -e "   \e[36mmigrateclean\e[0m|\e[36mmc\e[0m     Compile and migrate with clean Smart Contracts to blockchain"
    echo -e "   \e[36mpublish\e[0m|\e[36mp\e[0m           Publish build artifacts to S3 bucket"
    echo -e "   \e[36mclean\e[0m|\e[36mc\e[0m             Clean Ethereum blockchain"
    echo -e "   \e[36mnginx\e[0m|\e[36mn\e[0m             Restart nginx Ethereum blockchain container"
    echo -e "   \e[36mupdate-dev-tool\e[0m|\e[36mudt\e[0m Update dev-tool container"
    echo -e "   \e[36mdownload-deployed-smart-contracts\e[0m|\e[36mddsc\e[0m Download deployed smart contracts"
    echo -e "   \e[36mhelp\e[0m|\e[36mh\e[0m|\e[36m?\e[0m            Show help"
    echo -e "   \e[34mwithout any command\e[0m - the same as Run"
    echo -e ""
    exit 0
fi
