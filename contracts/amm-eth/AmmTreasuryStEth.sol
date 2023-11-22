// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../basic/amm/AmmTreasuryGenOne.sol";

contract AmmTreasuryStEth is AmmTreasuryGenOne {
    constructor(
        address assetInput,
        address routerInput,
        address ammStorageInput
    ) AmmTreasuryGenOne(assetInput, routerInput, ammStorageInput) {}
}
