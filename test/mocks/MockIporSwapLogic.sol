// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/amm/libraries/IporSwapLogic.sol";

contract MockIporSwapLogic {
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 totalAmount,
        uint256 leverage,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) public view returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        return
            IporSwapLogic.calculateSwapAmount(
                tenor,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );
    }

    function calculateInterest(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (uint256 interestFixed, uint256 interestFloating) {
        return IporSwapLogic.calculateInterest(swap, closingTimestamp, mdIbtPrice);
    }

    function calculateInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) public pure returns (uint256) {
        return IporSwapLogic.calculateInterestFixed(notional, swapFixedInterestRate, swapPeriodInSeconds);
    }

    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice) public pure returns (uint256) {
        return IporSwapLogic.calculateInterestFloating(ibtQuantity, ibtCurrentPrice);
    }

    function calculatePnlPayFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = IporSwapLogic.calculatePnlPayFixed(swap, closingTimestamp, mdIbtPrice);
    }

    function calculatePnlReceiveFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = IporSwapLogic.calculatePnlReceiveFixed(swap, closingTimestamp, mdIbtPrice);
    }

    function calculateSwapUnwindPnlValue(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) public pure returns (int256 swapUnwindAmount) {
        swapUnwindAmount = IporSwapLogic.calculateSwapUnwindPnlValue(
            swap,
            closingTimestamp,
            oppositeLegFixedRate
        );
    }

    function calculateSwapUnwindOpeningFeeAmount(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) public pure returns (uint256 swapOpeningFeeAmount) {
        swapOpeningFeeAmount = IporSwapLogic.calculateSwapUnwindOpeningFeeAmount(
            swap,
            closingTimestamp,
            openingFeeRateCfg
        );
    }
}
