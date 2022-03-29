// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/MiltonErrors.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IJoseph.sol";
import "../configuration/JosephConfiguration.sol";
import "hardhat/console.sol";

abstract contract Joseph is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    JosephConfiguration,
    IJoseph
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    modifier onlyCharlieTreasuryManager() {
        require(
            msg.sender == _charlieTreasuryManager,
            JosephErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    modifier onlyTreasuryManager() {
        require(msg.sender == _treasuryManager, JosephErrors.CALLER_NOT_TREASURE_TRANSFERER);
        _;
    }

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
        _milton = IMilton(milton);
        _miltonStorage = IMiltonStorage(miltonStorage);
        _stanley = IStanley(stanley);
    }

    function getVersion() external pure override virtual returns (uint256) {
        return 1;
    }
	
	function getAsset() external view override returns (address) {
        return _asset;
    }

    function calculateExchangeRate() external view override returns (uint256) {
        return _calculateExchangeRate(block.timestamp);
    }

    //@param liquidityAmount underlying token amount represented in decimals specific for underlying asset
    function provideLiquidity(uint256 liquidityAmount) external override whenNotPaused {
        _provideLiquidity(liquidityAmount, _getDecimals(), block.timestamp);
    }

    //@param ipTokenValue IpToken amount represented in 18 decimals
    function redeem(uint256 ipTokenValue) external override whenNotPaused {
        _redeem(ipTokenValue, block.timestamp);
    }

    function rebalance() external override whenNotPaused {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();

        require(totalBalance != 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);

        if (ratio > _MILTON_STANLEY_BALANCE_PERCENTAGE) {
            uint256 assetValue = wadMiltonAssetBalance -
                IporMath.division(_MILTON_STANLEY_BALANCE_PERCENTAGE * totalBalance, Constants.D18);
            _milton.depositToStanley(assetValue);
        } else {
            uint256 assetValue = IporMath.division(
                _MILTON_STANLEY_BALANCE_PERCENTAGE * totalBalance,
                Constants.D18
            ) - wadMiltonAssetBalance;
            _milton.withdrawFromStanley(assetValue);
        }
    }

    //@param assetValue underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetValue) external override onlyOwner whenNotPaused {
        _milton.depositToStanley(assetValue);
    }

    //@param assetValue underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetValue) external override onlyOwner whenNotPaused {
        _milton.withdrawFromStanley(assetValue);
    }

    //@param assetValue underlying token amount represented in 18 decimals
    function transferToTreasury(uint256 assetValue)
        external
        override
        nonReentrant
        whenNotPaused
        onlyTreasuryManager
    {
        require(address(0) != _treasury, JosephErrors.INCORRECT_TREASURE_TREASURER);

        _miltonStorage.updateStorageWhenTransferToTreasury(assetValue);

        uint256 assetValueAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetValue,
            _getDecimals()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            _treasury,
            assetValueAssetDecimals
        );
    }

    //@param assetValue underlying token amount represented in 18 decimals
    function transferToCharlieTreasury(uint256 assetValue)
        external
        override
        nonReentrant
        whenNotPaused
        onlyCharlieTreasuryManager
    {
        require(address(0) != _charlieTreasury, JosephErrors.INCORRECT_CHARLIE_TREASURER);

        _miltonStorage.updateStorageWhenTransferToCharlieTreasury(assetValue);

        uint256 assetValueAssetDecimals = IporMath.convertWadToAssetDecimals(
            assetValue,
            _getDecimals()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            _charlieTreasury,
            assetValueAssetDecimals
        );
    }

    function checkVaultReservesRatio() external view override returns (uint256) {
        return _checkVaultReservesRatio();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _calculateExchangeRate(uint256 calculateTimestamp) internal view returns (uint256) {
        IMilton milton = _milton;

        (, , int256 soap) = milton.calculateSoapForTimestamp(calculateTimestamp);

        int256 balance = milton.getAccruedBalance().liquidityPool.toInt256() - soap;

        require(balance >= 0, MiltonErrors.SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = _ipToken.totalSupply();

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

    function _getIporTotalBalance()
        internal
        view
        returns (uint256 totalBalance, uint256 wadMiltonAssetBalance)
    {
        address miltonAddr = address(_milton);

        wadMiltonAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(_asset).balanceOf(miltonAddr),
            _getDecimals()
        );

        totalBalance = wadMiltonAssetBalance + _stanley.totalBalance(miltonAddr);
    }

    //@param assetValue in decimals like asset
    function _provideLiquidity(
        uint256 assetValue,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal nonReentrant {
        IMilton milton = _milton;

        uint256 exchangeRate = _calculateExchangeRate(timestamp);

        require(exchangeRate != 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetValue = IporMath.convertToWad(assetValue, assetDecimals);

        _miltonStorage.addLiquidity(wadAssetValue);

        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(milton), assetValue);

        uint256 ipTokenValue = IporMath.division(wadAssetValue * Constants.D18, exchangeRate);
        _ipToken.mint(msg.sender, ipTokenValue);

        emit ProvideLiquidity(
            timestamp,
            msg.sender,
            address(milton),
            exchangeRate,
            assetValue,
            ipTokenValue
        );
    }

    function _redeem(uint256 ipTokenValue, uint256 timestamp) internal nonReentrant {
        require(
            ipTokenValue != 0 && ipTokenValue <= _ipToken.balanceOf(msg.sender),
            JosephErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        IMilton milton = _milton;

        uint256 exchangeRate = _calculateExchangeRate(timestamp);

        require(exchangeRate != 0, MiltonErrors.LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetValue = IporMath.division(ipTokenValue * exchangeRate, Constants.D18);

        uint256 wadRedeemFee = IporMath.division(
            wadAssetValue * _getRedeemFeePercentage(),
            Constants.D18
        );

        uint256 wadRedeemValue = wadAssetValue - wadRedeemFee;

        IporTypes.MiltonBalancesMemory memory balance = _milton.getAccruedBalance();

        uint256 assetValue = IporMath.convertWadToAssetDecimals(wadRedeemValue, _getDecimals());

        uint256 utilizationRate = _calculateRedeemedUtilizationRate(
            balance.liquidityPool,
            balance.payFixedTotalCollateral + balance.receiveFixedTotalCollateral,
            wadRedeemValue
        );

        require(
            utilizationRate <= _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE,
            JosephErrors.REDEEM_LP_UTILIZATION_EXCEEDED
        );

        _ipToken.burn(msg.sender, ipTokenValue);

        _miltonStorage.subtractLiquidity(wadRedeemValue);

        IERC20Upgradeable(_asset).safeTransferFrom(address(_milton), msg.sender, assetValue);

        emit Redeem(
            timestamp,
            address(milton),
            msg.sender,
            exchangeRate,
            assetValue,
            ipTokenValue,
            wadRedeemFee,
            wadRedeemValue
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

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
