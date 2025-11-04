// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import {IAmmPoolsServiceWstEth} from "../interfaces/IAmmPoolsServiceWstEth.sol";
import {AmmPoolsServiceWstEthBaseV2} from "../../../base/amm-wstEth/services/AmmPoolsServiceWstEthBaseV2.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev This contract extends AmmPoolsServiceWstEthBaseV2 with Asset Management support.
/// @dev Asset Management is supported in this contract. Rebalancing between AMM Treasury and Asset Management IS supported in this contract.
contract AmmPoolsServiceWstEth is AmmPoolsServiceWstEthBaseV2 {
    constructor(
        address wstEthInput,
        address ipwstEthInput,
        address ammTreasuryWstEthInput,
        address ammStorageWstEthInput,
        address ammAssetManagementInput,
        address iporOracleInput,
        address iporProtocolRouterInput,
        uint256 redeemFeeRateWstEthInput,
        uint256 autoRebalanceThresholdMultiplier_
    )
        AmmPoolsServiceWstEthBaseV2(
            wstEthInput,
            ipwstEthInput,
            ammTreasuryWstEthInput,
            ammStorageWstEthInput,
            ammAssetManagementInput,
            iporOracleInput,
            iporProtocolRouterInput,
            redeemFeeRateWstEthInput,
            autoRebalanceThresholdMultiplier_
        )
    {}

    /// @notice Override to emit Arbitrum-specific ProvideLiquidityWstEth event
    function _emitProvideLiquidityEvent(
        address beneficiary,
        uint256 exchangeRate,
        uint256 wadAssetAmount,
        uint256 ipTokenAmount
    ) internal virtual override {
        emit IAmmPoolsServiceWstEth.ProvideLiquidityWstEth(
            msg.sender,
            beneficiary,
            ammTreasury,
            exchangeRate,
            wadAssetAmount,
            ipTokenAmount
        );
    }

    /// @notice Override to emit Arbitrum-specific RedeemWstEth event
    function _emitRedeemEvent(
        address beneficiary,
        uint256 exchangeRate,
        uint256 wadAssetAmount,
        uint256 wadAmountToRedeem,
        uint256 ipTokenAmount
    ) internal virtual override {
        emit IAmmPoolsServiceWstEth.RedeemWstEth(
            ammTreasury,
            msg.sender,
            beneficiary,
            exchangeRate,
            wadAssetAmount,
            wadAmountToRedeem,
            ipTokenAmount
        );
    }
}
