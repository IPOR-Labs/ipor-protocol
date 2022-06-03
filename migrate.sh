#!/usr/bin/env bash

set -e -o pipefail

MIGRATION_PREFIX="migration-"

BEGIN_MIGRATION=0

CURRENT_MIGRATION_NUMBER=${BEGIN_MIGRATION}

MIGRATION_TAG_NAME="${MIGRATION_PREFIX}${CURRENT_MIGRATION_NUMBER}"

git log --oneline -n 5

echo "-----------------------------------------------------------"

git checkout migration-0

git log --oneline -n 5

echo "-----------------------------------------------------------"

git checkout migration-1

git log --oneline -n 5
