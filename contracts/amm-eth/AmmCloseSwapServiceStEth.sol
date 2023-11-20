// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/IAmmCloseSwapLensStEth.sol";
import "../interfaces/IAmmCloseSwapServiceStEth.sol";
import "../basic/amm/services/AmmCloseSwapServiceGenOne.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmCloseSwapServiceStEth is AmmCloseSwapServiceGenOne, IAmmCloseSwapServiceStEth, IAmmCloseSwapLensStEth {
    constructor(
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput
    ) AmmCloseSwapServiceGenOne(poolCfg, iporOracleInput, messageSignerInput) {}

    function getClosingSwapDetailsStEth(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        return _getClosingSwapDetails(account, direction, swapId, closeTimestamp, riskIndicatorsInput);
    }

    function closeSwapsStEth(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            beneficiary,
            payFixedSwapIds,
            receiveFixedSwapIds,
            riskIndicatorsInput
        );
    }

    function emergencyCloseSwapsStEth(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _emergencyCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            riskIndicatorsInput
        );
    }
}
