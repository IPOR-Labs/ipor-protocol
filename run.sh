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

ENV_CONFIG_FILE_SRC="smart-contract-address.yaml.j2"
ENV_CONFIG_FILE_DEST="smart-contract-address.yaml"
ENV_CONFIG_FILE_RMT="${ENV_PROFILE}/smart-contract-address.yaml"

ENV_CONTRACTS_ROOT_DIR="app/src"
ENV_CONTRACTS_DIR="${ENV_CONTRACTS_ROOT_DIR}/contracts"
ENV_CONTRACTS_ZIP_DEST="${ENV_CONTRACTS_ROOT_DIR}/contracts.zip"
ENV_CONTRACTS_ZIP_RMT="${ENV_PROFILE}/contracts.zip"

AWS_REGION="eu-central-1"

IS_MIGRATE_SC="NO"
IS_BUILD_DOCKER="NO"
IS_RUN="NO"
IS_HELP="NO"
IS_PUBLISH_ARTIFACTS="NO"


if [ $# -eq 0 ]; then
    IS_RUN="YES"
fi

while test $# -gt 0
do
    case "$1" in
        migrate|m)
            IS_MIGRATE_SC="YES"
        ;;
        build|b)
            IS_BUILD_DOCKER="YES"
        ;;
        run|r)
            IS_RUN="YES"
        ;;
        publish|p)
            IS_PUBLISH_ARTIFACTS="YES"
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

function set_smart_contract_address(){
  local FILE_NAME="${1}"
  local VAR_NAME="${2}"
  local VAR_VALUE=$(jq '.networks[].address' "${ENV_CONTRACTS_DIR}/${FILE_NAME}")
  sed -i "s/${VAR_NAME}.*/${VAR_NAME}: ${VAR_VALUE}/" "${ENV_CONFIG_FILE_DEST}"
}

function create_env_config_file(){
  cp "${ENV_CONFIG_FILE_SRC}" "${ENV_CONFIG_FILE_DEST}"

  set_smart_contract_address "Milton.json" "milton_address"
  set_smart_contract_address "Warren.json" "warren_address"
  set_smart_contract_address "TestMilton.json" "milton_test_address"
  set_smart_contract_address "TestWarren.json" "warren_test_address"
  set_smart_contract_address "MiltonDevToolDataProvider.json" "milton_dev_tool_data_provider_address"
  set_smart_contract_address "MiltonFrontendDataProvider.json" "milton_frontend_data_provider_address"
  set_smart_contract_address "DaiMockedToken.json" "dai_mocked_address"
  set_smart_contract_address "UsdcMockedToken.json" "usdc_mocked_address"
  set_smart_contract_address "UsdtMockedToken.json" "usdt_mocked_address"

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


################################### COMMANDS ###################################

if [ $IS_BUILD_DOCKER = "YES" ]; then

  cd "${DIR}"
  npm install
  truffle compile

  cd "${DIR}/app"
  echo -e "\n\e[32mBuild Milton Tool docker...\e[0m\n"

  docker build -t io.ipor/ipor-protocol-milton-tool .

  cd "${DIR}/containers/nginx-ganache"
  echo -e "\n\e[32mBuild nginx-ganche docker...\e[0m\n"

  docker build -t io.ipor/nginx-ganche:latest .
fi


if [ $IS_RUN = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mStopping Milton Tool docker...\e[0m\n"
  docker-compose -f docker-compose.yml rm -s -v -f

  echo -e "\n\e[32mStarting Milton Tool docker..\e[0m\n"
  docker-compose -f docker-compose.yml up -d --remove-orphans
fi


if [ $IS_MIGRATE_SC = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mMigrate Smart Contracts to Ganache Blockchain...\e[0m\n"

  truffle migrate --network docker --reset --compile-none
fi


if [ $IS_PUBLISH_ARTIFACTS = "YES" ]; then
  cd "${DIR}"

  echo -e "\n\e[32mPublish artifacts to S3 bucket: ${ENV_CONFIG_BUCKET}/${ENV_PROFILE}\e[0m\n"

  create_env_config_file
  create_contracts_zip

  put_file_to_bucket "${ENV_CONTRACTS_ZIP_DEST}" "${ENV_CONTRACTS_ZIP_RMT}"
  put_file_to_bucket "${ENV_CONFIG_FILE_DEST}" "${ENV_CONFIG_FILE_RMT}"
fi


if [ $IS_HELP = "YES" ]; then
    echo -e "usage: \e[32m./run.sh\e[0m [cmd1] [cmd2] [cmd3]"
    echo -e ""
    echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
    echo -e "   \e[36mbuild\e[0m|\e[36mb\e[0m       Build Milton Tool docker"
    echo -e "   \e[36mrun\e[0m|\e[36mr\e[0m         Run / restart Milton Tool"
    echo -e "   \e[36mmigrate\e[0m|\e[36mm\e[0m     Compile and migrate Smart Contracts to Blockchain"
    echo -e "   \e[36mpublish\e[0m|\e[36mp\e[0m     Publish build artifacts to S3 bucket"
    echo -e "   \e[36mhelp\e[0m|\e[36mh\e[0m|\e[36m?\e[0m      Show help"
    echo -e "   \e[34mwithout any command\e[0m - the same as Run"
    echo -e ""
    exit 0
fi
