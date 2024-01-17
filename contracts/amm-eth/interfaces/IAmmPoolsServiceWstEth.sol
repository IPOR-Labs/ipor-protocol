// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsServiceWstEth contract.
interface IAmmPoolsServiceWstEth {

    function provideLiquidityWstEth(address beneficiary, uint256 stEthAmount) external;

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
