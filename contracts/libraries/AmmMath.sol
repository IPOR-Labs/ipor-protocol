// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";

library AmmMath {

    function calculateIbtQuantity(string memory asset, uint256 notionalAmount, uint256 ibtPrice) public view returns (uint256){
        return notionalAmount * 1e18 / ibtPrice;
    }
}