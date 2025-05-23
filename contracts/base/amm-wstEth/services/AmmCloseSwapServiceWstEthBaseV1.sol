// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import "../../../interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../base/amm/services/AmmCloseSwapServiceBaseV1.sol";
import {StorageLibBaseV1} from "../../libraries/StorageLibBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
/// @dev Close Swap Service for wstEth pool - Asset Management IS NOT supported in this contract.
contract AmmCloseSwapServiceWstEthBaseV1 is AmmCloseSwapServiceBaseV1, IAmmCloseSwapServiceWstEth {
    using IporContractValidator for address;

    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracle_
    ) AmmCloseSwapServiceBaseV1(poolCfg, iporOracle_) {}

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
