// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/libraries/errors/IporErrors.sol";
import "../../contracts/libraries/errors/MiltonErrors.sol";
import "../../contracts/libraries/errors/JosephErrors.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/libraries/math/IporMath.sol";
import "./MockJosephInternal.sol";

abstract contract MockJoseph is MockJosephInternal {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    function calculateExchangeRate() external view returns (uint256) {
        return _calculateExchangeRate(block.timestamp);
    }

    function provideLiquidity(uint256 assetAmount) external whenNotPaused {
        _provideLiquidity(assetAmount, _getDecimals(), block.timestamp);
    }

    function redeem(uint256 ipTokenAmount) external whenNotPaused {
        _redeem(ipTokenAmount, block.timestamp);
    }

    function checkVaultReservesRatio() external view returns (uint256) {
        return _checkVaultReservesRatio();
    }

    function _calculateExchangeRate(uint256 calculateTimestamp) internal view returns (uint256) {
        IMiltonInternal milton = _getMilton();

        (, , int256 soap) = milton.calculateSoapAtTimestamp(calculateTimestamp);

        int256 balance = milton.getAccruedBalance().liquidityPool.toInt256() - soap;

        require(balance >= 0, MiltonErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = _getIpToken().totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance.toUint256() * Constants.D18, ipTokenTotalSupply);
        } else {
            return Constants.D18;
        }
    }

    function _checkVaultReservesRatio() internal view returns (uint256) {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();
        require(totalBalance > 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);
        return IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);
    }

    function _provideLiquidity(
        uint256 assetAmount,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal nonReentrant {
        address msgSender = _msgSender();
        IMiltonInternal milton = _getMilton();

        uint256 exchangeRate = _calculateExchangeRate(timestamp);

        require(exchangeRate > 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, assetDecimals);

        _getMiltonStorage().addLiquidity(
            msgSender,
            wadAssetAmount,
            _maxLiquidityPoolBalance * Constants.D18,
            _maxLpAccountContribution * Constants.D18
        );

        IERC20Upgradeable(_asset).safeTransferFrom(msgSender, address(milton), assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * Constants.D18, exchangeRate);

        _getIpToken().mint(msgSender, ipTokenAmount);

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
        require(
            ipTokenAmount > 0 && ipTokenAmount <= _getIpToken().balanceOf(_msgSender()),
            JosephErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        IMiltonInternal milton = _getMilton();

        uint256 exchangeRate = _calculateExchangeRate(timestamp);

        require(exchangeRate > 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, Constants.D18);

        uint256 wadRedeemFee = IporMath.division(
            wadAssetAmount * _getRedeemFeeRate(),
            Constants.D18
        );

        uint256 redeemAmount = IporMath.convertWadToAssetDecimals(
            wadAssetAmount - wadRedeemFee,
            _getDecimals()
        );

        uint256 wadRedeemAmount = IporMath.convertToWad(redeemAmount, _getDecimals());

        IporTypes.MiltonBalancesMemory memory balance = _getMilton().getAccruedBalance();

        uint256 utilizationRate = _calculateRedeemedUtilizationRate(
            balance.liquidityPool,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            wadRedeemAmount
        );

        require(
            utilizationRate <= _getRedeemLpMaxUtilizationRate(),
            JosephErrors.REDEEM_LP_UTILIZATION_EXCEEDED
        );

        _getIpToken().burn(_msgSender(), ipTokenAmount);

        _getMiltonStorage().subtractLiquidity(wadRedeemAmount);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_getMilton()),
            _msgSender(),
            redeemAmount
        );

        emit Redeem(
            timestamp,
            address(milton),
            _msgSender(),
            exchangeRate,
            wadAssetAmount,
            ipTokenAmount,
            wadRedeemFee,
            wadRedeemAmount
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

    /// @notice Emitted when `from` account provides liquidity (ERC20 token supported by IPOR Protocol) to Milton Liquidity Pool
    event ProvideLiquidity(
        /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
        /// @notice address that provides liquidity
        address from,
        /// @notice Milton's address where liquidity is received
        address to,
        /// @notice current ipToken exchange rate
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice amount of asset provided by user to Milton's liquidity pool
        /// @dev value represented in 18 decimals
        uint256 assetAmount,
        /// @notice amount of ipToken issued to represent user's share in the liquidity pool.
        /// @dev value represented in 18 decimals
        uint256 ipTokenAmount
    );

    /// @notice Emitted when `to` accound executes redeem ipTokens
    event Redeem(
        /// @notice moment in which ipTokens were redeemed by `to` account
        uint256 timestamp,
        /// @notice Milton's address from which underlying asset - ERC20 Tokens, are transferred to `to` account
        address from,
        /// @notice account where underlying asset tokens are transferred after redeem
        address to,
        /// @notice ipToken exchange rate used for calculating `assetAmount`
        /// @dev value represented in 18 decimals
        uint256 exchangeRate,
        /// @notice underlying asset value calculated based on `exchangeRate` and `ipTokenAmount`
        /// @dev value represented in 18 decimals
        uint256 assetAmount,
        /// @notice redeemed IP Token value
        /// @dev value represented in 18 decimals
        uint256 ipTokenAmount,
        /// @notice underlying asset fee deducted when redeeming ipToken.
        /// @dev value represented in 18 decimals
        uint256 redeemFee,
        /// @notice net asset amount transferred from Milton to `to`/sender's account, reduced by the redeem fee
        /// @dev value represented in 18 decimals
        uint256 redeemAmount
    );
}
