// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IMiltonStorage.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../libraries/Constants.sol";
import "../interfaces/IMilton.sol";

contract Joseph is
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    PausableUpgradeable,
    IJoseph
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_PERCENTAGE = 1e18;

    uint8 internal _decimals;
    address internal _asset;
    IIpToken private _ipToken;
    IMilton private _milton;
    IMiltonStorage private _miltonStorage;

    function initialize(
        address assetAddress,
        address ipToken,
        address milton,
        address miltonStorage
    ) public initializer {
        __Ownable_init();
        require(address(assetAddress) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(milton) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(miltonStorage) != address(0), IporErrors.WRONG_ADDRESS);

        _asset = assetAddress;
        _decimals = ERC20Upgradeable(assetAddress).decimals();
        _ipToken = IIpToken(ipToken);
        _milton = IMilton(milton);
        _miltonStorage = IMiltonStorage(miltonStorage);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function asset() external view returns (address) {
        return _asset;
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

        DataTypes.MiltonTotalBalanceMemory memory balance = _miltonStorage
            .getBalance();

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
