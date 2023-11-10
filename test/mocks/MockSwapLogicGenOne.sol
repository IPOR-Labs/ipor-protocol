// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/basic/amm/libraries/SwapLogicGenOne.sol";

contract MockSwapLogicGenOne {
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 totalAmount,
        uint256 leverage,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) public view returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        return
            SwapLogicGenOne.calculateSwapAmount(
                tenor,
                totalAmount,
                leverage,
                liquidationDepositAmount,
                iporPublicationFeeAmount,
                openingFeeRate
            );
    }

    function calculateInterest(
        AmmTypesGenOne.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (uint256 interestFixed, uint256 interestFloating) {
        return SwapLogicGenOne.calculateInterest(swap, closingTimestamp, mdIbtPrice);
    }


    function calculatePnlPayFixed(
        AmmTypesGenOne.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = SwapLogicGenOne.calculatePnlPayFixed(swap, closingTimestamp, mdIbtPrice);
    }

    function calculatePnlReceiveFixed(
        AmmTypesGenOne.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) public pure returns (int256 swapValue) {
        swapValue = SwapLogicGenOne.calculatePnlReceiveFixed(swap, closingTimestamp, mdIbtPrice);
    }

    function calculateSwapUnwindPnlValue(
        AmmTypesGenOne.Swap memory swap,
        AmmTypes.SwapDirection direction,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) public pure returns (int256 swapUnwindAmount) {
        swapUnwindAmount = SwapLogicGenOne.calculateSwapUnwindPnlValue(
            swap,
            closingTimestamp,
            oppositeLegFixedRate
        );
    }

    function calculateSwapUnwindOpeningFeeAmount(
        AmmTypesGenOne.Swap memory swap,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) public pure returns (uint256 swapOpeningFeeAmount) {
        swapOpeningFeeAmount = SwapLogicGenOne.calculateSwapUnwindOpeningFeeAmount(
            swap,
            closingTimestamp,
            openingFeeRateCfg
        );
    }
}
