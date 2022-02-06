// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IMiltonStorage.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../libraries/Constants.sol";
import "../interfaces/IMilton.sol";

contract Joseph is UUPSUpgradeable, OwnableUpgradeable, IJoseph {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 private constant _REDEEM_LP_MAX_UTYLIZATION_PERCENTAGE = 1e18;

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

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function asset() external view returns (address) {
        return _asset;
    }

    function provideLiquidity(uint256 liquidityAmount) external override {
        _provideLiquidity(liquidityAmount, _decimals, block.timestamp);
    }

    function redeem(uint256 ipTokenVolume) external override {
        _redeem(ipTokenVolume, block.timestamp);
    }

    //@param liquidityAmount in decimals like asset
    function _provideLiquidity(
        uint256 liquidityAmount,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal {
        uint256 exchangeRate = _milton.calculateExchangeRate(timestamp);

        require(exchangeRate != 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadLiquidityAmount = IporMath.convertToWad(
            liquidityAmount,
            assetDecimals
        );

        _miltonStorage.addLiquidity(wadLiquidityAmount);

        //TODO: account Address from OZ and use call
        //TODO: use call instead transfer if possible!!

        //TODO: add from address to black list
        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(_milton),
            liquidityAmount
        );

        if (exchangeRate != 0) {
            _ipToken.mint(
                msg.sender,
                IporMath.division(
                    wadLiquidityAmount * Constants.D18,
                    exchangeRate
                )
            );
        }
    }

    function _redeem(uint256 ipTokenVolume, uint256 timestamp) internal {
        require(
            ipTokenVolume != 0 &&
                ipTokenVolume <= _ipToken.balanceOf(msg.sender),
            IporErrors.MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );

        uint256 exchangeRate = _milton.calculateExchangeRate(timestamp);

        require(exchangeRate != 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        DataTypes.MiltonTotalBalanceMemory memory balance = _miltonStorage
            .getBalance();

        uint256 wadUnderlyingAmount = IporMath.division(
            ipTokenVolume * exchangeRate,
            Constants.D18
        );

        require(
            balance.liquidityPool > wadUnderlyingAmount,
            IporErrors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW
        );

        uint256 underlyingAmount = IporMath.convertWadToAssetDecimals(
            wadUnderlyingAmount,
            _decimals
        );

        uint256 utilizationRate = _calculateRedeemedUtilizationRate(
            balance.liquidityPool,
            balance.payFixedSwaps + balance.receiveFixedSwaps,
            wadUnderlyingAmount
        );

        require(
            utilizationRate <= _REDEEM_LP_MAX_UTYLIZATION_PERCENTAGE,
            IporErrors.JOSEPH_REDEEM_LP_UTILIZATION_EXCEEDED
        );

        _ipToken.burn(msg.sender, msg.sender, ipTokenVolume);

        _miltonStorage.subtractLiquidity(wadUnderlyingAmount);

        IERC20Upgradeable(_asset).safeTransferFrom(
            address(_milton),
            msg.sender,
            underlyingAmount
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
}
