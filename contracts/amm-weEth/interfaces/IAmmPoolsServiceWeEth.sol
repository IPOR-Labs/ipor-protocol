// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

/// @title Interface of the AmmPoolsServiceWeEth contract.
interface IAmmPoolsServiceWeEth {
    function provideLiquidityWeEthToAmmPoolWeEth(address beneficiary, uint256 weEthAmount) external;

    function provideLiquidity(
        address poolAsset,
        address inputAsset,
        address beneficiary,
        uint256 inputAssetAmount
    ) external payable returns (uint256 ipTokenAmount);

    function redeemFromAmmPoolWeEth(address beneficiary, uint256 ipTokenAmount) external;

    error ProvideLiquidityFailed(address poolAsset, string errorCode, string errorMessage);
}
