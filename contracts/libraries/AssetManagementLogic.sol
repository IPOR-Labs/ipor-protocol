// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAssetManagement.sol";
import "../governance/AmmConfigurationManager.sol";

library AssetManagementLogic {
    using SafeCast for uint256;

    function calculateRebalanceAmountBeforeWithdraw(
        address asset,
        uint256 wadAmmErc20BalanceBeforeWithdraw,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal view returns (int256) {
        return
            IporMath.divisionInt(
                (wadAmmErc20BalanceBeforeWithdraw.toInt256() +
                    vaultBalance.toInt256() -
                    wadOperationAmount.toInt256()) *
                    (Constants.D18_INT - AmmConfigurationManager.getAmmAndAssetManagementRatio(asset).toInt256()),
                Constants.D18_INT
            ) - vaultBalance.toInt256();
    }
}
