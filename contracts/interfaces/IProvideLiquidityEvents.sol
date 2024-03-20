// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IProvideLiquidityEvents {
    event ProvideLiquidity(
        address poolAsset,
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event Redeem(
        address poolAsset,
        address indexed ammTreasury,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amount,
        uint256 redeemedAmount,
        uint256 ipTokenAmount
    );
}
