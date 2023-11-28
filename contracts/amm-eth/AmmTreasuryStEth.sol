// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../base/amm/AmmTreasuryBaseV1.sol";

contract AmmTreasuryStEth is AmmTreasuryBaseV1 {
    constructor(
        address assetInput,
        address routerInput,
        address ammStorageInput
    ) AmmTreasuryBaseV1(assetInput, routerInput, ammStorageInput) {}
}
