// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./errors/IporErrors.sol";
import "./errors/AmmErrors.sol";
import "../interfaces/IAmmCloseSwapLens.sol";
import "../interfaces/types/IporTypes.sol";

library AmmCloseSwapServicePoolConfigurationLib {
    function getTimeBeforeMaturityAllowedToCloseSwapByBuyer(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        IporTypes.SwapTenor tenor
    ) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days;
        } else {
            revert IporErrors.UnsupportedTenor(AmmErrors.UNSUPPORTED_SWAP_TENOR, uint256(tenor));
        }
    }

    function getTimeAfterOpenAllowedToCloseSwapWithUnwinding(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        IporTypes.SwapTenor tenor
    ) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days;
        } else {
            revert IporErrors.UnsupportedTenor(AmmErrors.UNSUPPORTED_SWAP_TENOR, uint256(tenor));
        }
    }
}
