#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

IS_GANACHE="NO"
IS_MIGRATE_SC="NO"
IS_BUILD_DOCKER="NO"
IS_RUN="NO"
IS_HELP="NO"

while test $# -gt 0
do
    case "$1" in
        ganache|g)
            IS_GANACHE="YES"
        ;;
        migrate|m)
            IS_MIGRATE_SC="YES"
        ;;
        build|b)
            IS_BUILD_DOCKER="YES"
        ;;
        run|r)
            IS_RUN="YES"
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

if [ $# -eq 0 ]; then

    IS_HELP="YES"
    IS_RUN="YES"
fi

# run ganache
if [ $IS_GANACHE = "YES" ]; then
  echo -e "\n\e[32mStarting Ganache Blockchain...\e[0m"

  cd "${DIR}/../ipor-blockchain"
  echo -e "\n\e[32mStopping Ganache docker...\e[0m\n"
  docker-compose -f ganache/docker-compose.yml rm -s -v -f

  echo -e "\n\e[32mStarting Ganache docker..\e[0m\n"
  docker-compose -f ganache/docker-compose.yml up -d --remove-orphans
fi

if [ $IS_MIGRATE_SC = "YES" ]; then
  cd "${DIR}/../ipor-protocol"

  echo -e "\n\e[32mCompile ipor-protocol Smart Contracts\e[0m\n"

  #git pull
  truffle compile

  echo -e "\n\e[32mMigrate Smart Contracts to Ganache Blockchain...\e[0m\n"

  truffle migrate --network docker --reset

fi

if [ $IS_BUILD_DOCKER = "YES" ]; then

  cd "${DIR}"
  truffle compile

  cd "${DIR}/app"
  echo -e "\n\e[32mBuild Milton Tool docker...\e[0m\n"

  docker build -t io.ipor/ipor-protocol-milton-tool .

  cd ..
fi

if [ $IS_RUN = "YES" ]; then
  echo -e "\n\e[32mStopping Milton Tool docker...\e[0m\n"
  docker-compose -f docker-compose.yml rm -s -v -f

  echo -e "\n\e[32mStarting Milton Tool docker..\e[0m\n"
  docker-compose -f docker-compose.yml up -d --remove-orphans
fi

if [ $IS_HELP = "YES" ]; then
    echo -e "usage: \e[32m./run.sh\e[0m [cmd1] [cmd2] [cmd3]"
    echo -e ""
    echo -e "commands can by joined together, order of commands doesn't matter, allowed commands:"
    echo -e "   \e[36mganache\e[0m|\e[36mg\e[0m     Run / restart Ganache Blockchain"
    echo -e "   \e[36mmigrate\e[0m|\e[36mm\e[0m     Compile and migrate Smart Contracts to Blockchain"
    echo -e "   \e[36mbuild\e[0m|\e[36mb\e[0m       Build Milton Tool docker"
    echo -e "   \e[36mrun\e[0m|\e[36mr\e[0m         Run / restartMilton Tool"
    echo -e "   \e[34mwithout any command\e[0m - do nothing"
    echo -e ""
    exit 1
fi