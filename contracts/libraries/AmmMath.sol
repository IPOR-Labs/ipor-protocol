// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";

library AmmMath {

    uint256 constant LAS_VEGAS_DECIMALS_FACTOR = 1e18;

    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice) public pure returns (uint256){
        return notionalAmount * LAS_VEGAS_DECIMALS_FACTOR / ibtPrice;
    }
}