// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../../libraries/errors/JosephErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IIpToken.sol";
import "../../interfaces/IJosephInternal.sol";
import "../../interfaces/IMiltonInternal.sol";
import "../../interfaces/IMiltonStorage.sol";
import "../../interfaces/IStanley.sol";
import "../../security/IporOwnableUpgradeable.sol";

abstract contract JosephInternal is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IJosephInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;

    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_RATE = 1e18;

    modifier onlyCharlieTreasuryManager() {
        require(_msgSender() == _charlieTreasuryManager, JosephErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER);
        _;
    }

    modifier onlyTreasuryManager() {
        require(_msgSender() == _treasuryManager, JosephErrors.CALLER_NOT_TREASURE_TRANSFERER);
        _;
    }

    modifier onlyAppointedToRebalance() {
        require(_appointedToRebalance[_msgSender()], JosephErrors.CALLER_NOT_APPOINTED_TO_REBALANCE);
        _;
    }


    function _getRedeemLpMaxUtilizationRate() internal pure virtual returns (uint256) {
        return _REDEEM_LP_MAX_UTILIZATION_RATE;
    }

    function rebalance() external override onlyAppointedToRebalance whenNotPaused nonReentrant {
        (uint256 totalBalance, uint256 wadMiltonAssetBalance) = _getIporTotalBalance();

        require(totalBalance > 0, JosephErrors.STANLEY_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadMiltonAssetBalance * Constants.D18, totalBalance);

        uint256 miltonStanleyBalanceRatio = _miltonStanleyBalanceRatio;

        if (ratio > miltonStanleyBalanceRatio) {
            uint256 assetAmount = wadMiltonAssetBalance -
                IporMath.division(miltonStanleyBalanceRatio * totalBalance, Constants.D18);
            if (assetAmount > 0) {
                _getMilton().depositToStanley(assetAmount);
            }
        } else {
            uint256 assetAmount = IporMath.division(miltonStanleyBalanceRatio * totalBalance, Constants.D18) -
                wadMiltonAssetBalance;
            if (assetAmount > 0) {
                _getMilton().withdrawFromStanley(assetAmount);
            }
        }
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external override onlyOwner whenNotPaused {
        _getMilton().depositToStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount) external override onlyOwner whenNotPaused {
        _getMilton().withdrawFromStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawAllFromStanley() external override onlyOwner whenNotPaused {
        _getMilton().withdrawAllFromStanley();
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToTreasury(uint256 assetAmount) external override nonReentrant whenNotPaused onlyTreasuryManager {
        address treasury = _treasury;
        require(address(0) != treasury, JosephErrors.INCORRECT_TREASURE_TREASURER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, _getDecimals());

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, _getDecimals());

        _getMiltonStorage().updateStorageWhenTransferToTreasury(wadAssetAmount);

        IERC20Upgradeable(_getAsset()).safeTransferFrom(address(_getMilton()), treasury, assetAmountAssetDecimals);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToCharlieTreasury(uint256 assetAmount)
        external
        override
        nonReentrant
        whenNotPaused
        onlyCharlieTreasuryManager
    {
        address charlieTreasury = _charlieTreasury;

        require(address(0) != charlieTreasury, JosephErrors.INCORRECT_CHARLIE_TREASURER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, _getDecimals());

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, _getDecimals());

        _getMiltonStorage().updateStorageWhenTransferToCharlieTreasury(wadAssetAmount);

        IERC20Upgradeable(_getAsset()).safeTransferFrom(
            address(_getMilton()),
            charlieTreasury,
            assetAmountAssetDecimals
        );
    }


    function getAutoRebalanceThreshold() external view override returns (uint256) {
        return _getAutoRebalanceThreshold();
    }

    function setAutoRebalanceThreshold(uint256 newAutoRebalanceThreshold) external override onlyOwner whenNotPaused {
        _setAutoRebalanceThreshold(newAutoRebalanceThreshold);
    }

    function getRedeemFeeRate() external view override returns (uint256) {
        return _getRedeemFeeRate();
    }

    function getRedeemLpMaxUtilizationRate() external pure override returns (uint256) {
        return _getRedeemLpMaxUtilizationRate();
    }

    function getMiltonStanleyBalanceRatio() external view override returns (uint256) {
        return _miltonStanleyBalanceRatio;
    }


    function _getIporTotalBalance() internal view returns (uint256 totalBalance, uint256 wadMiltonAssetBalance) {
        address miltonAddr = address(_getMilton());

        wadMiltonAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(_getAsset()).balanceOf(miltonAddr),
            _getDecimals()
        );

        totalBalance = wadMiltonAssetBalance + _getStanley().totalBalance(miltonAddr);
    }

    function _getAutoRebalanceThreshold() internal view returns (uint256) {
        return _autoRebalanceThresholdInThousands * Constants.D21;
    }

    function _setAutoRebalanceThreshold(uint256 newAutoRebalanceThresholdInThousands) internal {
        uint256 oldAutoRebalanceThresholdInThousands = _autoRebalanceThresholdInThousands;
        _autoRebalanceThresholdInThousands = newAutoRebalanceThresholdInThousands.toUint32();
        emit AutoRebalanceThresholdChanged(
            _msgSender(),
            oldAutoRebalanceThresholdInThousands * Constants.D18,
            newAutoRebalanceThresholdInThousands * Constants.D18
        );
    }

    function _getAsset() internal view virtual returns (address) {
        return _asset;
    }

    function _getDecimals() internal view virtual returns (uint256);

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
