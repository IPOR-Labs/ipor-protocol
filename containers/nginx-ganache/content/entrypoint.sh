#!/usr/bin/env bash

set -e

SHELL_SOCK="/tmp/shell.sock"

echo "pgrep"
SOCKPROC_EXISTS=1 #"$( pgrep sockproc )"
echo "END pgrep"

if [ -z "$SOCKPROC_EXISTS" ]; then
  echo "sockproc exists on PID: ${SOCKPROC_EXISTS}"
else
  if [ -f "${EXISTS}" ]; then
    echo "remove old file: ${SHELL_SOCK}"
    rm "${SHELL_SOCK}"
  fi

  echo "sockproc start, executing: /etc/sockproc/sockproc ${SHELL_SOCK}"
  /etc/sockproc/sockproc "${SHELL_SOCK}"
fi

echo "start openresty: "
echo $@
exec "$@"
