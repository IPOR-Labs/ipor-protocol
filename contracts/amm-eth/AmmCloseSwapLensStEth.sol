// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/IAmmCloseSwapLensStEth.sol";
import "../interfaces/IAmmCloseSwapServiceStEth.sol";
import "../base/amm/services/AmmCloseSwapLensBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmCloseSwapLensStEth is AmmCloseSwapLensBaseV1, IAmmCloseSwapLensStEth {
    constructor(
        address iporOracleInput,
        address messageSignerInput,
        address closeSwapServiceStEthInput
    ) AmmCloseSwapLensBaseV1(iporOracleInput, messageSignerInput, closeSwapServiceStEthInput) {}

    function getClosingSwapDetailsStEth(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        return _getClosingSwapDetails(account, direction, swapId, closeTimestamp, riskIndicatorsInput);
    }
}
