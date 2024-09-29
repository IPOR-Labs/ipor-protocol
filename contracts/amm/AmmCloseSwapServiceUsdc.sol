// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {AmmTypes} from "../interfaces/types/AmmTypes.sol";
import {IAmmCloseSwapLens} from "../interfaces/IAmmCloseSwapLens.sol";
import {IAmmCloseSwapServiceUsdc} from "../interfaces/IAmmCloseSwapServiceUsdc.sol";
import {AmmCloseSwapServiceStable}  from "./AmmCloseSwapServiceStable.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmCloseSwapServiceUsdc is AmmCloseSwapServiceStable, IAmmCloseSwapServiceUsdc {
    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput
    ) AmmCloseSwapServiceStable(poolCfg, iporOracleInput, messageSignerInput) {}

    function closeSwapsUsdc(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
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

    function emergencyCloseSwapsUsdc(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            msg.sender,
            payFixedSwapIds,
            receiveFixedSwapIds,
            riskIndicatorsInput
        );
    }
}
