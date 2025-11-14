// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {IAmmCloseSwapServiceWstEth} from "../../../interfaces/IAmmCloseSwapServiceWstEth.sol";
import {AmmCloseSwapServiceBaseV2} from "../../../base/amm/services/AmmCloseSwapServiceBaseV2.sol";
import {StorageLibBaseV1} from "../../libraries/StorageLibBaseV1.sol";
import {AmmTypes} from "../../../interfaces/types/AmmTypes.sol";
import {IAmmCloseSwapLens} from "../../../interfaces/IAmmCloseSwapLens.sol";


/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
/// @dev Close Swap Service for wstEth pool - Asset Management (PlasmaVault from Ipor Fusion) and rebalancing between AMM Treasury 
/// and Asset Management (PlasmaVault from Ipor Fusion) IS supported in this contract.
contract AmmCloseSwapServiceWstEthBaseV2 is AmmCloseSwapServiceBaseV2, IAmmCloseSwapServiceWstEth {
    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracle_
    ) AmmCloseSwapServiceBaseV2(poolCfg, iporOracle_) {}

    function closeSwapsWstEth(
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

    function emergencyCloseSwapsWstEth(
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

    function _getMessageSigner() internal view override returns (address) {
        return StorageLibBaseV1.getMessageSignerStorage().value;
    }
}
