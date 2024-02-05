// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsServiceWstEth contract.
interface IAmmPoolsServiceUsdm {

    function provideLiquidityUsdmToAmmPoolUsdm(address beneficiary, uint256 usdmAmount) external payable;

    function redeemFromAmmPoolUsdm(address beneficiary, uint256 ipTokenAmount) external;

    event ProvideLiquidityUsdm(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event RedeemUsdm(
        address indexed ammTreasuryUsdm,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amountUsdm,
        uint256 redeemedAmountUsdm,
        uint256 ipTokenAmount
    );
}
