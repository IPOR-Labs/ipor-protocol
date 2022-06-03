#!/usr/bin/env bash

set -e -o pipefail

git log --oneline -n 5

echo "-----------------------------------------------------------"

git checkout migration-0

git log --oneline -n 5

echo "-----------------------------------------------------------"

git checkout migration-1

git log --oneline -n 5
