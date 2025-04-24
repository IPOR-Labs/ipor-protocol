// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import {IAmmPoolsServiceWstEthBaseV2} from "../../../base/amm-wstEth/interfaces/IAmmPoolsServiceWstEthBaseV2.sol";
import {AmmPoolsServiceBaseV1} from "../../../base/amm/services/AmmPoolsServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Asset Management is supported in this contract. Rebalancing between AMM Treasury and Asset Management IS supported in this contract.   
contract AmmPoolsServiceWstEthBaseV2 is IAmmPoolsServiceWstEthBaseV2, AmmPoolsServiceBaseV1 {
    constructor(
        address asset_,
        address ipToken_,
        address ammTreasury_,
        address ammStorage_,
        address ammAssetManagement_,
        address iporOracle_,
        address iporProtocolRouter_,
        uint256 redeemFeeRate_,
        uint256 autoRebalanceThresholdMultiplier_
    )
        AmmPoolsServiceBaseV1(
            asset_,
            ipToken_,
            ammTreasury_,
            ammStorage_,
            ammAssetManagement_,
            iporOracle_,
            iporProtocolRouter_,
            redeemFeeRate_,
            autoRebalanceThresholdMultiplier_
        )
    {}

    function provideLiquidityWstEth(address beneficiary, uint256 assetAmount) external payable override {
        _provideLiquidity(beneficiary, assetAmount);
    }

    function redeemFromAmmPoolWstEth(address beneficiary, uint256 ipTokenAmount) external override {
        _redeem(beneficiary, ipTokenAmount);
    }

    function rebalanceBetweenAmmTreasuryAndAssetManagementWstEth() external override {
        _rebalanceBetweenAmmTreasuryAndAssetManagement();
    }
}
