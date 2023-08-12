// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAmmPoolsServiceEth {
    function provideLiquidityStEth(address beneficiary, uint256 assetAmount) external payable;

    function provideLiquidityWEth(address beneficiary, uint256 assetAmount) external payable;

    function provideLiquidityEth(address beneficiary, uint256 assetAmount) external payable;

    error StEthSubmitFailed(uint256 amount, string errorCode);

    event ProvideStEthLiquidity(
        uint256 timestamp,
        address from,
        address beneficiary,
        address to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event ProvideEthLiquidity(
        uint256 timestamp,
        address from,
        address beneficiary,
        address to,
        uint256 exchangeRate,
        uint256 amountEth,
        uint256 amountStEth,
        uint256 ipTokenAmount
    );
}
