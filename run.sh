#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${DIR}/../ipor-blockchain"

echo -e "\n\e[32mStopping Ganache docker...\e[0m\n"
docker-compose -f ganache/docker-compose.yml rm -s -v -f

echo -e "\n\e[32mStarting Ganache docker..\e[0m\n"
docker-compose -f ganache/docker-compose.yml up -d --remove-orphans

cd "${DIR}/../ipor-protocol"

echo -e "\n\e[32mCompile ipor-protocol Smart Contracts\e[0m\n"

git pull
truffle compile

echo -e "\n\e[32mMigrate Smart Contracts to Ganache Blockchain...\e[0m\n"

truffle migrate --network docker --reset

#echo -e "\n\e[32mBuild frontend...\e[0m\n"

#npm install
#npm run build

cd "${DIR}/app"
echo -e "\n\e[32mBuild Milton Tool docker...\e[0m\n"

docker build -t io.ipor/ipor-protocol-milton-tool .

cd ..

echo -e "\n\e[32mStopping Milton Tool docker...\e[0m\n"
docker-compose -f docker-compose.yml rm -s -v -f

echo -e "\n\e[32mStarting Milton Tool docker..\e[0m\n"
docker-compose -f docker-compose.yml up -d --remove-orphans
