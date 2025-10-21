// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title Interface of the AmmPoolsServiceWstEthBaseV1 contract.
interface IAmmPoolsServiceWstEthBaseV1 {
    /// @notice Provides liquidity to the AMM pool. Provide wstETH asset to wstETH Pool.
    /// @param beneficiary The address of the beneficiary.
    /// @param stEthAmount The amount of stETH asset to provide.
    function provideLiquidityWstEth(address beneficiary, uint256 stEthAmount) external payable;

    /// @notice Redeems from the AMM pool. Redeem wstETH asset from wstETH Pool.
    /// @param beneficiary The address of the beneficiary.
    /// @param ipTokenAmount The amount of ipToken asset to redeem.
    function redeemFromAmmPoolWstEth(address beneficiary, uint256 ipTokenAmount) external;

    event ProvideLiquidityWstEth(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event RedeemWstEth(
        address indexed ammTreasuryEth,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amountStEth,
        uint256 redeemedAmountStEth,
        uint256 ipTokenAmount
    );
}
