// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../libraries/types/JosephTypes.sol";
import "../../interfaces/IJoseph.sol";
import "./JosephInternal.sol";

abstract contract Joseph is JosephInternal, IJoseph {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    function calculateExchangeRate() external view override returns (uint256) {
        IMiltonInternal milton = _getMilton();
        return
            _calculateExchangeRate(
                block.timestamp,
                milton,
                _getIpToken(),
                milton.getAccruedBalance().liquidityPool
            );
    }

    function provideLiquidity(uint256 assetAmount) external override whenNotPaused {
        _provideLiquidity(assetAmount, _getDecimals(), block.timestamp);
    }

    function redeem(uint256 ipTokenAmount) external override whenNotPaused {
        _redeem(ipTokenAmount, block.timestamp);
    }

    function _calculateExchangeRate(
        uint256 calculateTimestamp,
        IMiltonInternal milton,
        IIpToken ipToken,
        uint256 liquidityPoolBalance
    ) internal view returns (uint256) {
        (, , int256 soap) = milton.calculateSoapAtTimestamp(calculateTimestamp);

        int256 balance = liquidityPoolBalance.toInt256() - soap;

        require(balance >= 0, MiltonErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = ipToken.totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * Constants.D18, ipTokenTotalSupply);
        } else {
            return Constants.D18;
        }
    }

    function _provideLiquidity(
        uint256 assetAmount,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal nonReentrant {
        address msgSender = _msgSender();
        address asset = _getAsset();
        IMiltonInternal milton = _getMilton();
        IIpToken ipToken = _getIpToken();

        IporTypes.MiltonBalancesMemory memory balance = milton.getAccruedBalance();

        uint256 exchangeRate = _calculateExchangeRate(
            timestamp,
            milton,
            ipToken,
            balance.liquidityPool
        );

        require(exchangeRate > 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, assetDecimals);

        _getMiltonStorage().addLiquidity(
            msgSender,
            wadAssetAmount,
            _maxLiquidityPoolBalance * Constants.D18,
            _maxLpAccountContribution * Constants.D18
        );

        IERC20Upgradeable(asset).safeTransferFrom(msgSender, address(milton), assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * Constants.D18, exchangeRate);

        ipToken.mint(msgSender, ipTokenAmount);

        /// @dev Order of the following two functions is important, first safeTransferFrom, then rebalanceIfNeededAfterProvideLiquidity.
        _rebalanceIfNeededAfterProvideLiquidity(milton, asset, balance.vault, wadAssetAmount);

        emit ProvideLiquidity(
            timestamp,
            msgSender,
            address(milton),
            exchangeRate,
            wadAssetAmount,
            ipTokenAmount
        );
    }

    function _redeem(uint256 ipTokenAmount, uint256 timestamp) internal nonReentrant {
        IIpToken ipToken = _getIpToken();
        require(
            ipTokenAmount > 0 && ipTokenAmount <= ipToken.balanceOf(_msgSender()),
            JosephErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        IMiltonInternal milton = _getMilton();

        IporTypes.MiltonBalancesMemory memory balance = milton.getAccruedBalance();

        uint256 exchangeRate = _calculateExchangeRate(
            timestamp,
            milton,
            ipToken,
            balance.liquidityPool
        );

        require(exchangeRate > 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        JosephTypes.RedeemMoney memory redeemMoney = _calculateRedeemMoney(
            ipTokenAmount,
            exchangeRate
        );

        uint256 wadMiltonErc20Balance = IporMath.convertToWad(
            IERC20Upgradeable(_getAsset()).balanceOf(address(milton)),
            _getDecimals()
        );

        require(
            wadMiltonErc20Balance + balance.vault > redeemMoney.wadRedeemAmount,
            JosephErrors.INSUFFICIENT_ERC20_BALANCE
        );

        _rebalanceIfNeededBeforeRedeem(
            milton,
            wadMiltonErc20Balance,
            balance.vault,
            redeemMoney.wadRedeemAmount
        );

        require(
            _calculateRedeemedUtilizationRate(
                balance.liquidityPool,
                balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
                redeemMoney.wadRedeemAmount
            ) <= _getRedeemLpMaxUtilizationRate(),
            JosephErrors.REDEEM_LP_UTILIZATION_EXCEEDED
        );

        ipToken.burn(_msgSender(), ipTokenAmount);

        _getMiltonStorage().subtractLiquidity(redeemMoney.wadRedeemAmount);

        IERC20Upgradeable(_getAsset()).safeTransferFrom(
            address(milton),
            _msgSender(),
            redeemMoney.redeemAmount
        );

        emit Redeem(
            timestamp,
            address(milton),
            _msgSender(),
            exchangeRate,
            redeemMoney.wadAssetAmount,
            ipTokenAmount,
            redeemMoney.wadRedeemFee,
            redeemMoney.wadRedeemAmount
        );
    }

    function _calculateRedeemedUtilizationRate(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralBalance,
        uint256 redeemedAmount
    ) internal pure returns (uint256) {
        uint256 denominator = totalLiquidityPoolBalance - redeemedAmount;
        if (denominator > 0) {
            return
                IporMath.division(
                    totalCollateralBalance * Constants.D18,
                    totalLiquidityPoolBalance - redeemedAmount
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }

    /// @dev Calculate redeem money
    /// @param ipTokenAmount Amount of ipToken to redeem
    /// @param exchangeRate Exchange rate of ipToken
    /// @return redeemMoney Redeem money struct
    function _calculateRedeemMoney(uint256 ipTokenAmount, uint256 exchangeRate)
        internal
        pure
        returns (JosephTypes.RedeemMoney memory redeemMoney)
    {
        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, Constants.D18);

        uint256 wadRedeemFee = IporMath.division(
            wadAssetAmount * _getRedeemFeeRate(),
            Constants.D18
        );

        uint256 redeemAmount = IporMath.convertWadToAssetDecimals(
            wadAssetAmount - wadRedeemFee,
            _getDecimals()
        );

        return
            JosephTypes.RedeemMoney({
                wadAssetAmount: wadAssetAmount,
                wadRedeemFee: wadRedeemFee,
                redeemAmount: redeemAmount,
                wadRedeemAmount: IporMath.convertToWad(redeemAmount, _getDecimals())
            });
    }

    function _rebalanceIfNeededBeforeRedeem(
        IMiltonInternal milton,
        uint256 wadMiltonErc20Balance,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        uint256 autoRebalanceThreshold = _getAutoRebalanceThreshold() * Constants.D21;

        if (autoRebalanceThreshold > 0) {
            if (wadOperationAmount >= autoRebalanceThreshold) {
                _withdrawFromStanleyBeforeRedeem(
                    milton,
                    wadMiltonErc20Balance,
                    vaultBalance,
                    wadOperationAmount
                );
            } else {
                if (wadOperationAmount > wadMiltonErc20Balance) {
                    _withdrawFromStanleyBeforeRedeem(
                        milton,
                        wadMiltonErc20Balance,
                        vaultBalance,
                        wadOperationAmount
                    );
                }
            }
        }
    }

    function _rebalanceIfNeededAfterProvideLiquidity(
        IMiltonInternal milton,
        address asset,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal {
        uint256 autoRebalanceTreshold = _getAutoRebalanceThreshold() * Constants.D21;

        if (autoRebalanceTreshold > 0 && wadOperationAmount >= autoRebalanceTreshold) {
            int256 rebalanceAmount = _calculateRebalanceAmountAfterProvideLiquidity(
                IporMath.convertToWad(
                    IERC20Upgradeable(asset).balanceOf(address(milton)),
                    _getDecimals()
                ),
                vaultBalance
            );

            if (rebalanceAmount > 0) {
                milton.depositToStanley(rebalanceAmount.toUint256());
            }
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

    function _calculateRebalanceAmountBeforeRedeem(
        uint256 wadMiltonErc20BalanceBeforeRedeem,
        uint256 vaultBalance,
        uint256 wadOperationAmount
    ) internal view returns (int256) {
        return
            IporMath.divisionInt(
                (wadMiltonErc20BalanceBeforeRedeem.toInt256() +
                    vaultBalance.toInt256() -
                    wadOperationAmount.toInt256()) *
                    (Constants.D18_INT - _miltonStanleyBalanceRatio.toInt256()),
                Constants.D18_INT
            ) - vaultBalance.toInt256();
    }

    /// @notice Calculate rebalance amount for provide liquidity
    /// @param wadMiltonErc20BalanceAfterDeposit Milton erc20 balance in wad, Notice: this is balance after provide liquidity operation!
    /// @param vaultBalance Vault balance in wad, Stanley's accrued balance.
    function _calculateRebalanceAmountAfterProvideLiquidity(
        uint256 wadMiltonErc20BalanceAfterDeposit,
        uint256 vaultBalance
    ) internal view returns (int256) {
        return
            IporMath.divisionInt(
                (wadMiltonErc20BalanceAfterDeposit + vaultBalance).toInt256() *
                    (Constants.D18_INT - _miltonStanleyBalanceRatio.toInt256()),
                Constants.D18_INT
            ) - vaultBalance.toInt256();
    }
}
