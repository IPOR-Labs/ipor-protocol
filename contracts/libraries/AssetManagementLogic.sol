// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./math/IporMath.sol";

library AssetManagementLogic {
    using SafeCast for uint256;

    /// @notice Calculate rebalance amount for liquidity provisioning
    /// @param wadAmmTreasuryErc20BalanceAfterDeposit AmmTreasury erc20 balance in wad, Notice: this balance is after providing liquidity operation!
    /// @param wadVaultBalance Vault balance in WAD, AssetManagement's accrued balance.
    /// @param wadAmmTreasuryAndAssetManagementRatioCfg AmmTreasury and AssetManagement Ratio taken from configuration.
    /// @dev If wadAmmTreasuryAndAssetManagementRatioCfg is 0, then no rebalance between AmmTreasury and Asset Management is turned off.
    /// @return int256 Rebalance amount. If positive then required to deposit, if negative then required to withdraw from Asset Management
    function calculateRebalanceAmountAfterProvideLiquidity(
        uint256 wadAmmTreasuryErc20BalanceAfterDeposit,
        uint256 wadVaultBalance,
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg
    ) internal pure returns (int256) {
        if (wadAmmTreasuryAndAssetManagementRatioCfg == 0) {
            return 0;
        }

        return
            IporMath.divisionInt(
                (wadAmmTreasuryErc20BalanceAfterDeposit + wadVaultBalance).toInt256() *
                    (1e18 - wadAmmTreasuryAndAssetManagementRatioCfg.toInt256()),
                1e18
            ) - wadVaultBalance.toInt256();
    }

    /// @notice Calculates rebalance amount before withdraw from pool.
    /// @param wadAmmErc20BalanceBeforeWithdraw ERC20 balance of the Amm Treasury before withdraw.
    /// @param vaultBalance ERC20 balance of the Vault.
    /// @param wadOperationAmount Amount of ERC20 tokens to withdraw.
    /// @param wadAmmTreasuryAndAssetManagementRatioCfg Amm Treasury and Asset Management Ratio.
    /// @dev If wadAmmTreasuryAndAssetManagementRatioCfg is 0, then no rebalance between AmmTreasury and Asset Management is turned off.
    /// @return int256 Rebalance amount. If positive then required to deposit, if negative then required to withdraw from Asset Management.
    /// @dev All values represented in WAD (18 decimals).
    function calculateRebalanceAmountBeforeWithdraw(
        uint256 wadAmmErc20BalanceBeforeWithdraw,
        uint256 vaultBalance,
        uint256 wadOperationAmount,
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg
    ) internal pure returns (int256) {
        if (wadAmmTreasuryAndAssetManagementRatioCfg == 0) {
            return 0;
        }

        return
            IporMath.divisionInt(
                (wadAmmErc20BalanceBeforeWithdraw.toInt256() +
                    vaultBalance.toInt256() -
                    wadOperationAmount.toInt256()) * (1e18 - wadAmmTreasuryAndAssetManagementRatioCfg.toInt256()),
                1e18
            ) - vaultBalance.toInt256();
    }
}
