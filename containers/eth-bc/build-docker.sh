#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${DIR}/.env"

if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
  echo -e "\n\e[32m${ENV_FILE} file was read\e[0m\n"
fi

BUILD_CONTAINER="ipor-geth"
BUILD_CONTAINER_IMAGE="io.ipor/${BUILD_CONTAINER}:1.10.12"

################################### FUNCTIONS ###################################

function build_geth_image() {
  echo -e "\n\e[32mBuild ${BUILD_CONTAINER} docker\e[0m\n"
  docker build -t "${BUILD_CONTAINER_IMAGE}" .
}

#################################### PROCESS ####################################

## Build Tool ##
build_geth_image

## BACKUP:
# docker run --rm --volumes-from ipor-protocol-eth-bc -v /home/rav/workspace/ipor-workspace/repos/ipor-protocol/containers/eth-bc/backup:/backup ubuntu tar cvf /backup/backup.tar /root
