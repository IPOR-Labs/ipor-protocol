// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./types/DataTypes.sol";
import "./Constants.sol";

library AmmMath {

    function calculateIbtQuantity(uint256 notionalAmount, uint256 ibtPrice) public pure returns (uint256){
        return notionalAmount * Constants.MILTON_DECIMALS_FACTOR / ibtPrice;
    }

    function calculateDerivativeAmount(
        uint256 totalAmount, uint8 leverage
    ) internal pure returns (DataTypes.IporDerivativeAmount memory) {
        uint256 openingFeeAmount = (totalAmount - Constants.LIQUIDATION_DEPOSIT_FEE_AMOUNT - Constants.IPOR_PUBLICATION_FEE_AMOUNT) * Constants.OPENING_FEE_PERCENTAGE / Constants.MILTON_DECIMALS_FACTOR;
        uint256 depositAmount = totalAmount - Constants.LIQUIDATION_DEPOSIT_FEE_AMOUNT - Constants.IPOR_PUBLICATION_FEE_AMOUNT - openingFeeAmount;
        return DataTypes.IporDerivativeAmount(
            depositAmount,
            leverage * depositAmount,
            openingFeeAmount
        );
    }
}