// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

library ProvideLiquidityEvents {
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
        address indexed ammTreasuryUsdm,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amountUsdm,
        uint256 redeemedAmountUsdm,
        uint256 ipTokenAmount
    );
}
