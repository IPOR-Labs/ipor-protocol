// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsServiceWstEth contract.
interface IAmmPoolsServiceUsdm {
    function provideLiquidityUsdmToAmmPoolUsdm(address beneficiary, uint256 usdmAmount) external payable;

    function redeemFromAmmPoolUsdm(address beneficiary, uint256 ipTokenAmount) external;
}
