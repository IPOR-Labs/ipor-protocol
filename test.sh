#!/bin/bash

set -e -o pipefail

forge test --fork-url https://eth-mainnet.g.alchemy.com/v2/Ba_wU9f6SEY3rKbZgrDTKihDcPpxiPw0 --match-path "test/fork/*" -vv

forge test --no-match-path "test/fork/*"

npm run test:mainnet
