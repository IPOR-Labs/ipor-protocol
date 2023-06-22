// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@ipor-protocol/contracts/interfaces/IAmmStorage.sol";
import "@ipor-protocol/contracts/interfaces/IAssetManagement.sol";
import "@ipor-protocol/contracts/libraries/Constants.sol";
import "@ipor-protocol/contracts/libraries/math/IporMath.sol";
import "@ipor-protocol/contracts/governance/AmmConfigurationManager.sol";

library AssetManagementLogic {
    using SafeCast for uint256;

    /// @notice Calculate rebalance amount before withdraw from pool.
    /// @param wadAmmErc20BalanceBeforeWithdraw ERC20 balance of the Amm Treasury before withdraw.
    /// @param vaultBalance ERC20 balance of the Vault.
    /// @param wadOperationAmount Amount of ERC20 tokens to withdraw.
    /// @param wadAmmTreasuryAndAssetManagementRatioCfg Amm Treasury and Asset Management Ratio.
    /// @return int256 Rebalance amount.
    /// @dev All values represented in WAD (18 decimals).
    function calculateRebalanceAmountBeforeWithdraw(
        uint256 wadAmmErc20BalanceBeforeWithdraw,
        uint256 vaultBalance,
        uint256 wadOperationAmount,
        uint256 wadAmmTreasuryAndAssetManagementRatioCfg
    ) internal pure returns (int256) {
        return
            IporMath.divisionInt(
                (wadAmmErc20BalanceBeforeWithdraw.toInt256() +
                    vaultBalance.toInt256() -
                    wadOperationAmount.toInt256()) *
                    (1e18 - wadAmmTreasuryAndAssetManagementRatioCfg.toInt256()),
                1e18
            ) - vaultBalance.toInt256();
    }
}
