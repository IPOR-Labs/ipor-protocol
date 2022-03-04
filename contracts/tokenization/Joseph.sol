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

import "../configuration/JosephConfiguration.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import {IporErrors} from "../IporErrors.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../libraries/Constants.sol";
import "hardhat/console.sol";

contract Joseph is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    JosephConfiguration,
    IJoseph
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    modifier onlyPublicationFeeTransferer() {
        require(
            msg.sender == _publicationFeeTransferer,
            IporErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    modifier onlyTreasureTransferer() {
        require(
            msg.sender == _treasureTransferer,
            IporErrors.CALLER_NOT_TREASURE_TRANSFERER
        );
        _;
    }

    function initialize(
        address assetAddress,
        address ipToken,
        address milton,
        address miltonStorage,
        address iporVault
    ) public initializer {
        __Ownable_init();
        require(address(assetAddress) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(milton) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(miltonStorage) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(iporVault) != address(0), IporErrors.WRONG_ADDRESS);

        _asset = assetAddress;
        _decimals = ERC20Upgradeable(assetAddress).decimals();
        _ipToken = IIpToken(ipToken);
        _milton = IMilton(milton);
        _miltonStorage = IMiltonStorage(miltonStorage);
        _iporVault = IIporVault(iporVault);
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function provideLiquidity(uint256 liquidityAmount)
        external
        override
        whenNotPaused
    {
        _provideLiquidity(liquidityAmount, _decimals, block.timestamp);
    }

    function redeem(uint256 ipTokenValue) external override whenNotPaused {
        _redeem(ipTokenValue, block.timestamp);
    }

    function rebalance() external override whenNotPaused {
        address miltonAddr = address(_milton);
        uint256 miltonAssetBalance = IERC20Upgradeable(_asset).balanceOf(
            miltonAddr
        );

        uint256 iporVaultAssetBalance = _iporVault.totalBalance(miltonAddr);

        uint256 ratio = IporMath.division(
            miltonAssetBalance * Constants.D18,
            miltonAssetBalance + iporVaultAssetBalance
        );

        if (ratio > _MILTON_STANLEY_BALANCE_PERCENTAGE) {
            uint256 assetValue = miltonAssetBalance -
                IporMath.division(
                    _MILTON_STANLEY_BALANCE_PERCENTAGE *
                        (miltonAssetBalance + iporVaultAssetBalance),
                    Constants.D18
                );
            _milton.depositToStanley(assetValue);
        } else {
            uint256 assetValue = IporMath.division(
                _MILTON_STANLEY_BALANCE_PERCENTAGE *
                    (miltonAssetBalance + iporVaultAssetBalance),
                Constants.D18
            ) - miltonAssetBalance;

            _milton.withdrawFromStanley(assetValue);
        }
    }

    function depositToStanley(uint256 assetValue)
        external
        override
        onlyOwner
        whenNotPaused
    {
        _milton.depositToStanley(assetValue);
    }

    function withdrawFromStanley(uint256 assetValue)
        external
        override
        onlyOwner
        whenNotPaused
    {
        _milton.withdrawFromStanley(assetValue);
    }

    function transferTreasury(uint256 assetValue)
        external
        override
        nonReentrant
        whenNotPaused
        onlyTreasureTransferer
    {
        require(
            address(0) != _treasureTreasurer,
            IporErrors.INCORRECT_TREASURE_TREASURER_ADDRESS
        );

        _miltonStorage.updateStorageWhenTransferTreasure(assetValue);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            _treasureTreasurer,
            assetValue
        );
    }

    function transferPublicationFee(uint256 assetValue)
        external
        override
        nonReentrant
        whenNotPaused
        onlyPublicationFeeTransferer
    {
        require(
            address(0) != _charlieTreasurer,
            IporErrors.INCORRECT_CHARLIE_TREASURER_ADDRESS
        );

        _miltonStorage.updateStorageWhenTransferPublicationFee(assetValue);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            _charlieTreasurer,
            assetValue
        );
    }

    //@notice Return reserve ration Milton Balance / (Milton Balance + Vault Balance) for a given asset
    function checkVaultReservesRatio()
        external
        view
        override
        returns (uint256)
    {
        return _checkVaultReservesRatio();
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _checkVaultReservesRatio() internal view returns (uint256) {
        address miltonAddr = address(_milton);
        uint256 miltonBalance = IERC20Upgradeable(_asset).balanceOf(miltonAddr);
        uint256 iporVaultAssetBalance = _iporVault.totalBalance(miltonAddr);
        uint256 balance = miltonBalance + iporVaultAssetBalance;
        require(balance != 0, IporErrors.MILTON_STANLEY_BALANCE_IS_EMPTY);
        return IporMath.division(miltonBalance * _decimals, balance);
    }

    //@param liquidityAmount in decimals like asset
    function _provideLiquidity(
        uint256 assetValue,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal {
        IMilton milton = _milton;

        uint256 exchangeRate = milton.calculateExchangeRate(timestamp);

        require(exchangeRate != 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadAssetValue = IporMath.convertToWad(
            assetValue,
            assetDecimals
        );

        _miltonStorage.addLiquidity(wadAssetValue);

        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(milton),
            assetValue
        );

        uint256 ipTokenValue = IporMath.division(
            wadAssetValue * Constants.D18,
            exchangeRate
        );
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

    function _redeem(uint256 ipTokenValue, uint256 timestamp) internal {
        require(
            ipTokenValue != 0 && ipTokenValue <= _ipToken.balanceOf(msg.sender),
            IporErrors.MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );
        IMilton milton = _milton;

        uint256 exchangeRate = milton.calculateExchangeRate(timestamp);

        require(exchangeRate != 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        DataTypes.MiltonBalanceMemory memory balance = _milton
            .getAccruedBalance();

        uint256 wadAssetValue = IporMath.division(
            ipTokenValue * exchangeRate,
            Constants.D18
        );

        require(
            balance.liquidityPool > wadAssetValue,
            IporErrors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW
        );

        uint256 assetValue = IporMath.convertWadToAssetDecimals(
            wadAssetValue,
            _decimals
        );

        uint256 utilizationRate = _calculateRedeemedUtilizationRate(
            balance.liquidityPool,
            balance.payFixedSwaps + balance.receiveFixedSwaps,
            wadAssetValue
        );

        require(
            utilizationRate <= _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE,
            IporErrors.JOSEPH_REDEEM_LP_UTILIZATION_EXCEEDED
        );

        _ipToken.burn(msg.sender, msg.sender, ipTokenValue);

        _miltonStorage.subtractLiquidity(wadAssetValue);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            msg.sender,
            assetValue
        );

        emit Redeem(
            timestamp,
            address(milton),
            msg.sender,
            exchangeRate,
            assetValue,
            ipTokenValue
        );
    }

    function _calculateRedeemedUtilizationRate(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralBalance,
        uint256 redeemedAmount
    ) internal pure returns (uint256) {
        return
            IporMath.division(
                totalCollateralBalance * Constants.D18,
                totalLiquidityPoolBalance - redeemedAmount
            );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
