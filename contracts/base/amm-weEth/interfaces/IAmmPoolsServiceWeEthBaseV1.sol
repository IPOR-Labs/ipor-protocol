// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

/// @title Interface for the base AmmPoolsService for weETH with Asset Management support
interface IAmmPoolsServiceWeEthBaseV1 {
    /// @notice Provides liquidity to the AMM pool using weETH tokens
    /// @param beneficiary Address that will receive ipweETH tokens
    /// @param weEthAmount Amount of weETH to deposit (in 18 decimals)
    function provideLiquidityWeEth(address beneficiary, uint256 weEthAmount) external payable;

    /// @notice Redeems ipweETH tokens and receives weETH
    /// @param beneficiary Address that will receive weETH tokens
    /// @param ipTokenAmount Amount of ipweETH tokens to redeem
    function redeemFromAmmPoolWeEth(address beneficiary, uint256 ipTokenAmount) external;

    /// @notice Rebalances assets between AMM Treasury and Asset Management (Plasma Vault)
    /// @dev Can only be called by addresses appointed to rebalance
    function rebalanceBetweenAmmTreasuryAndAssetManagementWeEth() external;
}
