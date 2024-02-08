// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsServiceWstEth contract.
interface IAmmPoolsServiceWeEth {
    function provideLiquidityWeEthToAmmPoolWeEth(address beneficiary, uint256 usdmAmount) external;

    function provideLiquidity(
        address poolAsset,
        address inputAsset,
        address beneficiary,
        uint256 inputAssetAmount
    ) external payable returns (uint256 ipTokenAmount);

    function redeemFromAmmPoolWeEth(address beneficiary, uint256 ipTokenAmount) external;

    error ProvideLiquidityFailed(
        address poolAsset,
        string errorCode,
        string errorMessage
    );

    event ProvideLiquidityWeEth(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event RedeemWeEth(
        address indexed ammTreasuryWeEth,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amountWeEth,
        uint256 redeemedAmountWeEth,
        uint256 ipTokenAmount
    );
}
