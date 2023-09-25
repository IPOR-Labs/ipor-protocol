// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../../contracts/libraries/AssetManagementLogic.sol";

contract MockAssetManagementLogic {
    function calculateRebalanceAmountAfterProvideLiquidity(
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit,
        uint256 vaultBalance,
        uint256 wadAmmTreasuryAndAssetManagementRatio
    ) public pure returns (int256) {
        return
            AssetManagementLogic.calculateRebalanceAmountAfterProvideLiquidity(
                wadAmmTreasuryErc20BalanceAfterDeposit,
                vaultBalance,
                wadAmmTreasuryAndAssetManagementRatio
            );
    }

    function calculateRebalanceAmountBeforeWithdraw(
        uint256 wadAmmErc20BalanceBeforeWithdraw,
        uint256 vaultBalance,
        uint256 wadOperationAmount,
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg
    ) public pure returns (int256) {
        return
            AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                wadAmmErc20BalanceBeforeWithdraw,
                vaultBalance,
                wadOperationAmount,
                wadAmmTreasuryAndAssetManagementRatioCfg
            );
    }
}
