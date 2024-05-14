// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "../interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../base/amm/services/AmmCloseSwapServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
contract AmmCloseSwapServiceWstEth is AmmCloseSwapServiceBaseV1, IAmmCloseSwapServiceWstEth {
    using IporContractValidator for address;

    address public immutable messageSigner;

    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput
    ) AmmCloseSwapServiceBaseV1(poolCfg, iporOracleInput) {
        messageSigner = messageSignerInput.checkAddress();
    }

    function getMessageSigner() public view override returns (address) {
        return messageSigner;
    }

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
}
