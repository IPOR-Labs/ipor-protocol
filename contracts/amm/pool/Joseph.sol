// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../libraries/AmmLib.sol";

import "../../interfaces/IJoseph.sol";
import "./JosephInternal.sol";

abstract contract Joseph is JosephInternal, IJoseph {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;


    function _calculateRedeemedUtilizationRate(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralBalance,
        uint256 redeemedAmount
    ) internal pure returns (uint256) {
        uint256 denominator = totalLiquidityPoolBalance - redeemedAmount;
        if (denominator > 0) {
            return
                IporMath.division(totalCollateralBalance * Constants.D18, totalLiquidityPoolBalance - redeemedAmount);
        } else {
            return Constants.MAX_VALUE;
        }
    }


    function _rebalanceIfNeededBeforeRedeem(
        IMiltonInternal milton,
        uint256 wadMiltonErc20Balance,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        uint256 autoRebalanceThreshold = _getAutoRebalanceThreshold();

        if (
            wadOperationAmount > wadMiltonErc20Balance ||
            (autoRebalanceThreshold > 0 && wadOperationAmount >= autoRebalanceThreshold)
        ) {
            _withdrawFromStanleyBeforeRedeem(milton, wadMiltonErc20Balance, vaultBalance, wadOperationAmount);
        }
    }


    function _withdrawFromStanleyBeforeRedeem(
        IMiltonInternal milton,
        uint256 wadMiltonErc20BalanceBeforeRedeem,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        int256 rebalanceAmount = _calculateRebalanceAmountBeforeRedeem(
            wadMiltonErc20BalanceBeforeRedeem,
            vaultBalance,
            wadOperationAmount
        );

        if (rebalanceAmount < 0) {
            milton.withdrawFromStanley((-rebalanceAmount).toUint256());
        }
    }

    function calculateRebalanceAmountBeforeWithdraw(
        uint256 wadMiltonErc20BalanceBeforeWithdraw,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) external view returns (int256) {
        return
            _calculateRebalanceAmountBeforeRedeem(
                wadMiltonErc20BalanceBeforeWithdraw,
                vaultBalance,
                wadOperationAmount
            );
    }

    function _calculateRebalanceAmountBeforeRedeem(
        uint256 wadMiltonErc20BalanceBeforeRedeem,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal view returns (int256) {
        return
            IporMath.divisionInt(
                (wadMiltonErc20BalanceBeforeRedeem.toInt256() +
                    vaultBalance.toInt256() -
                    wadOperationAmount.toInt256()) * (Constants.D18_INT - _miltonStanleyBalanceRatio.toInt256()),
                Constants.D18_INT
            ) - vaultBalance.toInt256();
    }


}
