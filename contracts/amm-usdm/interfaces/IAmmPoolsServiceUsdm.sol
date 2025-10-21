// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title Interface of the AmmPoolsServiceUsdm contract.
interface IAmmPoolsServiceUsdm {
    function provideLiquidityUsdmToAmmPoolUsdm(address beneficiary, uint256 usdmAmount) external payable;

    function redeemFromAmmPoolUsdm(address beneficiary, uint256 ipTokenAmount) external;
}
