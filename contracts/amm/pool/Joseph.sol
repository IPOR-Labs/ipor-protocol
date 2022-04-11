// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IJoseph.sol";
import "./JosephInternal.sol";
import "hardhat/console.sol";

abstract contract Joseph is JosephInternal, IJoseph {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    function initialize(
        address initAsset,
        address ipToken,
        address milton,
        address miltonStorage,
        address stanley
    ) public initializer {
        __Ownable_init();

        require(initAsset != address(0), IporErrors.WRONG_ADDRESS);
        require(ipToken != address(0), IporErrors.WRONG_ADDRESS);
        require(milton != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _getDecimals() == ERC20Upgradeable(initAsset).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        IIpToken iipToken = IIpToken(ipToken);
        require(initAsset == iipToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = initAsset;
        _ipToken = iipToken;
        _milton = IMiltonInternal(milton);
        _miltonStorage = IMiltonStorage(miltonStorage);
        _stanley = IStanley(stanley);
    }

    function calculateExchangeRate() external view override returns (uint256) {
        return _calculateExchangeRate(block.timestamp);
    }

    //@param assetAmount underlying token amount represented in decimals specific for underlying asset
    function provideLiquidity(uint256 assetAmount) external override whenNotPaused {
        _provideLiquidity(assetAmount, _getDecimals(), block.timestamp);
    }

    //@param ipTokenAmount IpToken amount represented in 18 decimals
    function redeem(uint256 ipTokenAmount) external override whenNotPaused {
        _redeem(ipTokenAmount, block.timestamp);
    }

    function checkVaultReservesRatio() external view override returns (uint256) {
        return _checkVaultReservesRatio();
    }

    function _calculateExchangeRate(uint256 calculateTimestamp) internal view returns (uint256) {
        IMiltonInternal milton = _getMilton();

        (, , int256 soap) = milton.calculateSoapAtTimestamp(calculateTimestamp);

        int256 balance = milton.getAccruedBalance().liquidityPool.toInt256() - soap;

        require(balance >= 0, MiltonErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = _getIpToken().totalSupply();

        if (ipTokenTotalSupply != 0) {
            return IporMath.division(balance.toUint256() * Constants.D18, ipTokenTotalSupply);
        } else {
            return Constants.D18;
        }
    }

    function _checkVaultReservesRatio() internal view returns (uint256) {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();
        require(totalBalance != 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);
        return IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);
    }

    //@param assetAmount in decimals like asset
    function _provideLiquidity(
        uint256 assetAmount,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal nonReentrant {
        IMiltonInternal milton = _getMilton();

        uint256 exchangeRate = _calculateExchangeRate(timestamp);

        require(exchangeRate != 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmount, assetDecimals);

        _getMiltonStorage().addLiquidity(wadAssetAmount);

        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(milton), assetAmount);

        uint256 ipTokenAmount = IporMath.division(wadAssetAmount * Constants.D18, exchangeRate);
        _getIpToken().mint(msg.sender, ipTokenAmount);

        emit ProvideLiquidity(
            timestamp,
            msg.sender,
            address(milton),
            exchangeRate,
            assetAmount,
            ipTokenAmount
        );
    }

    function _redeem(uint256 ipTokenAmount, uint256 timestamp) internal nonReentrant {
        require(
            ipTokenAmount != 0 && ipTokenAmount <= _getIpToken().balanceOf(msg.sender),
            JosephErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        IMiltonInternal milton = _getMilton();

        uint256 exchangeRate = _calculateExchangeRate(timestamp);

        require(exchangeRate != 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetAmount = IporMath.division(ipTokenAmount * exchangeRate, Constants.D18);

        uint256 wadRedeemFee = IporMath.division(
            wadAssetAmount * _getRedeemFeeRate(),
            Constants.D18
        );

        uint256 wadRedeemAmount = wadAssetAmount - wadRedeemFee;

        IporTypes.MiltonBalancesMemory memory balance = _getMilton().getAccruedBalance();

        uint256 assetAmount = IporMath.convertWadToAssetDecimals(wadRedeemAmount, _getDecimals());

        uint256 utilizationRate = _calculateRedeemedUtilizationRate(
            balance.liquidityPool,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed,
            wadRedeemAmount
        );

        require(
            utilizationRate <= _REDEEM_LP_MAX_UTILIZATION_RATE,
            JosephErrors.REDEEM_LP_UTILIZATION_EXCEEDED
        );

        _getIpToken().burn(msg.sender, ipTokenAmount);

        _getMiltonStorage().subtractLiquidity(wadRedeemAmount);

        IERC20Upgradeable(_asset).safeTransferFrom(address(_getMilton()), msg.sender, assetAmount);

        emit Redeem(
            timestamp,
            address(milton),
            msg.sender,
            exchangeRate,
            assetAmount,
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
        if (denominator != 0) {
            return
                IporMath.division(
                    totalCollateralBalance * Constants.D18,
                    totalLiquidityPoolBalance - redeemedAmount
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
