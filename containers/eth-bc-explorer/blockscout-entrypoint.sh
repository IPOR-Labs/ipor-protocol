#!/usr/bin/env bash

set -e

WRONG_MIGRATION_FILE="/opt/app/apps/explorer/priv/repo/migrations/20211018164843_transactions_block_number_block_hash_index.exs"

if [ -f "${WRONG_MIGRATION_FILE}" ]; then
  rm "${WRONG_MIGRATION_FILE}"
  echo "Wrong migration file was removed: ${WRONG_MIGRATION_FILE}"
fi

mix do ecto.create, ecto.migrate
exec mix phx.server
