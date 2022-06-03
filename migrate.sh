#!/usr/bin/env bash

set -e -o pipefail

echo "-----------------------------------------------------------"
echo "--------------------- migration-0 -------------------------"
echo "-----------------------------------------------------------"

git checkout migration-0

git status
git log --oneline -n 5
./run.sh migrate

echo "-----------------------------------------------------------"
echo "--------------------- migration-1 -------------------------"
echo "-----------------------------------------------------------"

git checkout migration-1

git status
git log --oneline -n 5
./run.sh migrate

echo "-----------------------------------------------------------"
echo "------------------------- END -----------------------------"
echo "-----------------------------------------------------------"