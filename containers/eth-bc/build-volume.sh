#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


################################### FUNCTIONS ###################################

function build_geth_volume() {
  cd "${DIR}/../.."
  #./run.sh b
  #./run.sh r
  #./run.sh m
  cd "${DIR}"
  docker run --rm --volumes-from ipor-protocol-eth-bc -v "${DIR}/backup":/backup busybox tar cvf /backup/backup.tar /root
}

#################################### PROCESS ####################################

## Build Tool ##
build_geth_volume
