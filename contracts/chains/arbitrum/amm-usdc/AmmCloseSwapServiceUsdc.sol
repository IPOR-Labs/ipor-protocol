// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {AmmTypes} from "../../../interfaces/types/AmmTypes.sol";
import {IAmmCloseSwapLens} from "../../../interfaces/IAmmCloseSwapLens.sol";
import {IAmmCloseSwapServiceUsdc} from "../../../interfaces/IAmmCloseSwapServiceUsdc.sol";
import {AmmCloseSwapServiceBaseV1} from "../../../base/amm/services/AmmCloseSwapServiceBaseV1.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
contract AmmCloseSwapServiceUsdc is AmmCloseSwapServiceBaseV1, IAmmCloseSwapServiceUsdc {

    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracle_
    ) AmmCloseSwapServiceBaseV1(poolCfg, iporOracle_) {}

    function getMessageSigner() public view override returns (address) {
        return StorageLibArbitrum.getMessageSignerStorage().value;
    }

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
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _emergencyCloseSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            riskIndicatorsInput
        );
    }
}
