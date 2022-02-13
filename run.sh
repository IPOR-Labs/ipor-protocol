#!/usr/bin/env bash

set -e

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

ENV_CONTRACTS_ROOT_DIR="app/src"
ENV_CONTRACTS_DIR="${ENV_CONTRACTS_ROOT_DIR}/contracts"
ENV_CONTRACTS_ZIP_DEST="${ENV_CONTRACTS_ROOT_DIR}/contracts.zip"
ENV_CONTRACTS_ZIP_RMT="${ENV_PROFILE}/contracts.zip"

ETH_BC_CONTAINER="ipor-protocol-eth-bc"
ETH_EXP_CONTAINER="ipor-protocol-eth-explorer"
ETH_EXP_POSTGRES_CONTAINER="ipor-protocol-eth-exp-postgres"

ETH_BC_DATA_VOLUME="ipor-protocol-eth-bc-data"
ETH_EXP_DATA_VOLUME="ipor-protocol-eth-exp-postgres-data"

NGINX_ETH_BC_CONTAINER="ipor-protocol-nginx-eth-bc"

AWS_REGION="eu-central-1"

ETH_BC_URL="http://localhost:9545"
GET_IP_TOKEN_METHOD_SIGNATURE="0xf64de4ed"

IS_MIGRATE_SC="NO"
IS_UPGRADE_SC="NO"
IS_BUILD_DOCKER="NO"
IS_CLEAN_BC="NO"
IS_RUN="NO"
IS_STOP="NO"
IS_HELP="NO"
IS_PUBLISH_ARTIFACTS="NO"
IS_NGINX_ETH_BC_RESTART="NO"

if [ $# -eq 0 ]; then
    IS_RUN="YES"
fi

while test $# -gt 0
do
    case "$1" in
        migrate|m)
            IS_MIGRATE_SC="YES"
        ;;
		upgrade|u)
            IS_UPGRADE_SC="YES"
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
  RESULT=$(set_smart_contract_address_from_json_file "Warren.json" "warren_address")
  RESULT=$(set_smart_contract_address_from_json_file "JosephUsdt.json" "joseph_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "JosephUsdc.json" "joseph_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "JosephDai.json" "joseph_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfMiltonUsdt.json" "itf_milton_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfMiltonUsdc.json" "itf_milton_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfMiltonDai.json" "itf_milton_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfWarren.json" "itf_warren_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfJosephUsdt.json" "itf_joseph_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfJosephUsdc.json" "itf_joseph_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "ItfJosephDai.json" "itf_joseph_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonDevToolDataProvider.json" "milton_dev_tool_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonFrontendDataProvider.json" "milton_frontend_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "WarrenDevToolDataProvider.json" "warren_dev_tool_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "WarrenFrontendDataProvider.json" "warren_frontend_data_provider_address")
  RESULT=$(set_smart_contract_address_from_json_file "DaiMockedToken.json" "dai_mocked_address")
  RESULT=$(set_smart_contract_address_from_json_file "UsdcMockedToken.json" "usdc_mocked_address")
  RESULT=$(set_smart_contract_address_from_json_file "UsdtMockedToken.json" "usdt_mocked_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonStorageUsdt.json" "milton_storage_usdt_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonStorageUsdc.json" "milton_storage_usdc_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonStorageDai.json" "milton_storage_dai_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonSpreadModel.json" "milton_spread_model_address")
  RESULT=$(set_smart_contract_address_from_json_file "MiltonFaucet.json" "milton_faucet_address")
  RESULT=$(set_smart_contract_address_from_json_file "IporConfiguration.json" "ipor_configuration_address")
  local IPOR_ASSET_CONFIG_USDC=$(set_smart_contract_address_from_json_file "IporAssetConfigurationUsdc.json" "ipor_asset_configuration_usdc_address")
  local IPOR_ASSET_CONFIG_USDT=$(set_smart_contract_address_from_json_file "IporAssetConfigurationUsdt.json" "ipor_asset_configuration_usdt_address")
  local IPOR_ASSET_CONFIG_DAI=$(set_smart_contract_address_from_json_file "IporAssetConfigurationDai.json" "ipor_asset_configuration_dai_address")
  RESULT=$(set_smart_contract_address_from_eth_method "${IPOR_ASSET_CONFIG_USDC}" "${GET_IP_TOKEN_METHOD_SIGNATURE}" "ipor_ip_token_usdc_address")
  RESULT=$(set_smart_contract_address_from_eth_method "${IPOR_ASSET_CONFIG_USDT}" "${GET_IP_TOKEN_METHOD_SIGNATURE}" "ipor_ip_token_usdt_address")
  RESULT=$(set_smart_contract_address_from_eth_method "${IPOR_ASSET_CONFIG_DAI}" "${GET_IP_TOKEN_METHOD_SIGNATURE}" "ipor_ip_token_dai_address")

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
  cd "${DIR}"

  echo -e "\n\e[32mMigrate Smart Contracts to Ethereum blockchain...\e[0m\n"
  rm -rf app/src/contracts/
  truffle compile --all
  truffle migrate --network docker --reset --compile-none
  
fi

if [ $IS_UPGRADE_SC = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mUpgrade Smart Contracts to Ethereum blockchain...\e[0m\n"
  truffle compile --all
  truffle migrate --network docker -f 4
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



if [ $IS_HELP = "YES" ]; then
    echo -e "usage: \e[32m./run.sh\e[0m [cmd1] [cmd2] [cmd3]"
    echo -e ""
    echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
    echo -e "   \e[36mbuild\e[0m|\e[36mb\e[0m       Build IPOR dockers"
    echo -e "   \e[36mrun\e[0m|\e[36mr\e[0m         Run / restart IPOR dockers"
    echo -e "   \e[36mstop\e[0m|\e[36ms\e[0m        Stop IPOR dockers"
    echo -e "   \e[36mmigrate\e[0m|\e[36mm\e[0m     Compile and migrate Smart Contracts to blockchain"
	echo -e "   \e[36mupgrade\e[0m|\e[36mu\e[0m     Upgrade Smart Contracts to blockchain"
    echo -e "   \e[36mpublish\e[0m|\e[36mp\e[0m     Publish build artifacts to S3 bucket"
    echo -e "   \e[36mclean\e[0m|\e[36mc\e[0m       Clean Ethereum blockchain"
    echo -e "   \e[36mnginx\e[0m|\e[36mn\e[0m       Restart nginx Ethereum blockchain container"
    echo -e "   \e[36mhelp\e[0m|\e[36mh\e[0m|\e[36m?\e[0m      Show help"
    echo -e "   \e[34mwithout any command\e[0m - the same as Run"
    echo -e ""
    exit 0
fi
