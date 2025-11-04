// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import {IAmmPoolsServiceWeEthBaseV1} from "../interfaces/IAmmPoolsServiceWeEthBaseV1.sol";
import {AmmPoolsServiceBaseV1} from "../../amm/services/AmmPoolsServiceBaseV1.sol";

/// @title Base contract for AMM Pools Service for weETH with Asset Management support
/// @notice Supports providing liquidity with weETH and includes auto-rebalancing between AMM Treasury and Asset Management (Plasma Vault)
/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Asset Management is supported in this contract. Rebalancing between AMM Treasury and Asset Management IS supported in this contract.
contract AmmPoolsServiceWeEthBaseV1 is IAmmPoolsServiceWeEthBaseV1, AmmPoolsServiceBaseV1 {
    constructor(
        address weEth_,
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
            weEth_,
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

    /// @notice Provides liquidity to the AMM pool using weETH tokens
    /// @param beneficiary Address that will receive ipweETH tokens
    /// @param weEthAmount Amount of weETH to deposit (in 18 decimals)
    function provideLiquidityWeEth(address beneficiary, uint256 weEthAmount) external payable virtual override {
        _provideLiquidity(beneficiary, weEthAmount);
    }

    /// @notice Redeems ipweETH tokens and receives weETH
    /// @param beneficiary Address that will receive weETH tokens
    /// @param ipTokenAmount Amount of ipweETH tokens to redeem
    function redeemFromAmmPoolWeEth(address beneficiary, uint256 ipTokenAmount) external virtual override {
        _redeem(beneficiary, ipTokenAmount);
    }

    /// @notice Rebalances assets between AMM Treasury and Asset Management (Plasma Vault)
    /// @dev Can only be called by addresses appointed to rebalance
    function rebalanceBetweenAmmTreasuryAndAssetManagementWeEth() external virtual override {
        _rebalanceBetweenAmmTreasuryAndAssetManagement();
    }
}
