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
import "contracts/libraries/errors/AmmPoolsErrors.sol";
import "contracts/libraries/Constants.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/interfaces/IIpToken.sol";
import "contracts/interfaces/IAmmTreasury.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/interfaces/IAssetManagement.sol";
import "contracts/security/IporOwnableUpgradeable.sol";

abstract contract MockJosephInternal is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;

    uint256 internal constant _REDEEM_FEE_RATE = 5e15;
    uint256 internal constant _REDEEM_LP_MAX_UTILIZATION_RATE = 1e18;

    address internal _asset;
    IIpToken internal _ipToken;
    IAmmTreasury internal _ammTreasury;
    IAmmStorage internal _ammStorage;
    IAssetManagement internal _assetManagement;

    address internal _treasury;
    address internal _treasuryManager;
    address internal _charlieTreasury;
    address internal _charlieTreasuryManager;

    uint256 internal _ammTreasuryAssetManagementBalanceRatio;
    uint32 internal _maxLiquidityPoolBalance;
    uint32 internal _maxLpAccountContribution;

    /// @dev The threshold for auto-rebalancing the pool. Value represented without decimals. Value represents multiplication of 1000.
    uint32 internal _autoRebalanceThresholdInThousands;

    modifier onlyCharlieTreasuryManager() {
        require(_msgSender() == _charlieTreasuryManager, AmmPoolsErrors.CALLER_NOT_PUBLICATION_FEE_TRANSFERER);
        _;
    }

    modifier onlyTreasuryManager() {
        require(_msgSender() == _treasuryManager, AmmPoolsErrors.CALLER_NOT_TREASURE_TRANSFERER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        bool paused,
        address initAsset,
        address ipToken,
        address ammTreasury,
        address ammStorage,
        address assetManagement
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        require(initAsset != address(0), IporErrors.WRONG_ADDRESS);
        require(ipToken != address(0), IporErrors.WRONG_ADDRESS);
        require(ammTreasury != address(0), IporErrors.WRONG_ADDRESS);
        require(ammStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(assetManagement != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == IERC20MetadataUpgradeable(initAsset).decimals(), IporErrors.WRONG_DECIMALS);

        if (paused) {
            _pause();
        }

        IIpToken iipToken = IIpToken(ipToken);
        require(initAsset == iipToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = initAsset;
        _ipToken = iipToken;
        _ammTreasury = IAmmTreasury(ammTreasury);
        _ammStorage = IAmmStorage(ammStorage);
        _assetManagement = IAssetManagement(assetManagement);
        _ammTreasuryAssetManagementBalanceRatio = 85e16;
        _maxLiquidityPoolBalance = 3_000_000;
        _maxLpAccountContribution = 50_000;
        _autoRebalanceThresholdInThousands = 50;
    }

    function getVersion() external pure virtual returns (uint256) {
        return 0;
    }

    function getAsset() external view returns (address) {
        return _getAsset();
    }

    function getAssetManagement() external view returns (address) {
        return address(_assetManagement);
    }

    function getAmmStorage() external view returns (address) {
        return address(_ammStorage);
    }

    function getAmmTreasury() external view returns (address) {
        return address(_ammTreasury);
    }

    function getIpToken() external view returns (address) {
        return address(_ipToken);
    }

    function setAmmTreasuryAssetManagementBalanceRatio(uint256 newRatio) external onlyOwner {
        require(newRatio > 0, AmmPoolsErrors.MILTON_ASSET_MANAGEMENT_RATIO);
        require(newRatio < 1e18, AmmPoolsErrors.MILTON_ASSET_MANAGEMENT_RATIO);
        _ammTreasuryAssetManagementBalanceRatio = newRatio;
    }

    function _getRedeemFeeRate() internal pure virtual returns (uint256) {
        return _REDEEM_FEE_RATE;
    }

    function _getRedeemLpMaxUtilizationRate() internal pure virtual returns (uint256) {
        return _REDEEM_LP_MAX_UTILIZATION_RATE;
    }

    function _getAssetManagement() internal view virtual returns (IAssetManagement) {
        return _assetManagement;
    }

    function _getAmmStorage() internal view virtual returns (IAmmStorage) {
        return _ammStorage;
    }

    function _getAmmTreasury() internal view virtual returns (IAmmTreasury) {
        return _ammTreasury;
    }

    function _getIpToken() internal view virtual returns (IIpToken) {
        return _ipToken;
    }

    function rebalance() external onlyOwner whenNotPaused {
        (uint256 totalBalance, uint256 wadAmmTreasuryAssetBalance) = _getIporTotalBalance();

        require(totalBalance > 0, AmmPoolsErrors.ASSET_MANAGEMENT_BALANCE_IS_EMPTY);

        uint256 ratio = IporMath.division(wadAmmTreasuryAssetBalance * Constants.D18, totalBalance);

        uint256 ammTreasuryAssetManagementBalanceRatio = _ammTreasuryAssetManagementBalanceRatio;

        if (ratio > ammTreasuryAssetManagementBalanceRatio) {
            uint256 assetAmount = wadAmmTreasuryAssetBalance -
                IporMath.division(ammTreasuryAssetManagementBalanceRatio * totalBalance, Constants.D18);
            _getAmmTreasury().depositToAssetManagement(assetAmount);
        } else {
            uint256 assetAmount = IporMath.division(ammTreasuryAssetManagementBalanceRatio * totalBalance, Constants.D18) -
                wadAmmTreasuryAssetBalance;
            _getAmmTreasury().withdrawFromAssetManagement(assetAmount);
        }
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function depositToAssetManagement(uint256 assetAmount) external onlyOwner whenNotPaused {
        _getAmmTreasury().depositToAssetManagement(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromAssetManagement(uint256 assetAmount) external onlyOwner whenNotPaused {
        _getAmmTreasury().withdrawFromAssetManagement(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawAllFromAssetManagement() external onlyOwner whenNotPaused {
        _getAmmTreasury().withdrawAllFromAssetManagement();
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToTreasury(uint256 assetAmount) external nonReentrant whenNotPaused onlyTreasuryManager {
        address treasury = _treasury;
        require(address(0) != treasury, AmmPoolsErrors.INCORRECT_TREASURE_TREASURER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, _getDecimals());

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, _getDecimals());

        _getAmmStorage().updateStorageWhenTransferToTreasury(wadAssetAmount);

        IERC20Upgradeable(_getAsset()).safeTransferFrom(address(_getAmmTreasury()), treasury, assetAmountAssetDecimals);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function transferToCharlieTreasury(uint256 assetAmount)
        external
        nonReentrant
        whenNotPaused
        onlyCharlieTreasuryManager
    {
        address charlieTreasury = _charlieTreasury;

        require(address(0) != charlieTreasury, AmmPoolsErrors.INCORRECT_CHARLIE_TREASURER);

        uint256 assetAmountAssetDecimals = IporMath.convertWadToAssetDecimals(assetAmount, _getDecimals());

        uint256 wadAssetAmount = IporMath.convertToWad(assetAmountAssetDecimals, _getDecimals());

        _getAmmStorage().updateStorageWhenTransferToCharlieTreasury(wadAssetAmount);

        IERC20Upgradeable(_getAsset()).safeTransferFrom(
            address(_getAmmTreasury()),
            charlieTreasury,
            assetAmountAssetDecimals
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getCharlieTreasury() external view returns (address) {
        return _charlieTreasury;
    }

    function setCharlieTreasury(address newCharlieTreasury) external onlyOwner whenNotPaused {
        require(newCharlieTreasury != address(0), AmmPoolsErrors.INCORRECT_CHARLIE_TREASURER);
        _charlieTreasury = newCharlieTreasury;
    }

    function getTreasury() external view returns (address) {
        return _treasury;
    }

    function setTreasury(address newTreasury) external onlyOwner whenNotPaused {
        require(newTreasury != address(0), IporErrors.WRONG_ADDRESS);
        _treasury = newTreasury;
    }

    function getCharlieTreasuryManager() external view returns (address) {
        return _charlieTreasuryManager;
    }

    function setCharlieTreasuryManager(address newCharlieTreasuryManager) external onlyOwner whenNotPaused {
        require(address(0) != newCharlieTreasuryManager, IporErrors.WRONG_ADDRESS);
        _charlieTreasuryManager = newCharlieTreasuryManager;
    }

    function getTreasuryManager() external view returns (address) {
        return _treasuryManager;
    }

    function setTreasuryManager(address newTreasuryManager) external onlyOwner whenNotPaused {
        require(address(0) != newTreasuryManager, IporErrors.WRONG_ADDRESS);
        _treasuryManager = newTreasuryManager;
    }

    function getMaxLiquidityPoolBalance() external view returns (uint256) {
        return _maxLiquidityPoolBalance;
    }

    function setMaxLiquidityPoolBalance(uint256 newMaxLiquidityPoolBalance) external onlyOwner whenNotPaused {
        _maxLiquidityPoolBalance = newMaxLiquidityPoolBalance.toUint32();
    }

    function getMaxLpAccountContribution() external view returns (uint256) {
        return _maxLpAccountContribution;
    }

    function setMaxLpAccountContribution(uint256 newMaxLpAccountContribution) external onlyOwner whenNotPaused {
        _maxLpAccountContribution = newMaxLpAccountContribution.toUint32();
    }

    function getAutoRebalanceThreshold() external view returns (uint256) {
        return _getAutoRebalanceThreshold();
    }

    function setAutoRebalanceThreshold(uint256 newAutoRebalanceThreshold) external onlyOwner whenNotPaused {
        _setAutoRebalanceThreshold(newAutoRebalanceThreshold);
    }

    function getRedeemFeeRate() external pure returns (uint256) {
        return _getRedeemFeeRate();
    }

    function getRedeemLpMaxUtilizationRate() external pure returns (uint256) {
        return _getRedeemLpMaxUtilizationRate();
    }

    function getAmmTreasuryAssetManagementBalanceRatio() external view returns (uint256) {
        return _ammTreasuryAssetManagementBalanceRatio;
    }

    function _getIporTotalBalance() internal view returns (uint256 totalBalance, uint256 wadAmmTreasuryAssetBalance) {
        address ammTreasuryAddr = address(_getAmmTreasury());

        wadAmmTreasuryAssetBalance = IporMath.convertToWad(
            IERC20Upgradeable(_getAsset()).balanceOf(ammTreasuryAddr),
            _getDecimals()
        );

        totalBalance = wadAmmTreasuryAssetBalance + _getAssetManagement().totalBalance(ammTreasuryAddr);
    }

    function _getAutoRebalanceThreshold() internal view returns (uint256) {
        return _autoRebalanceThresholdInThousands * Constants.D21;
    }

    function _setAutoRebalanceThreshold(uint256 newAutoRebalanceThresholdInThousands) internal {
        _autoRebalanceThresholdInThousands = newAutoRebalanceThresholdInThousands.toUint32();
    }

    function _getAsset() internal view virtual returns (address) {
        return _asset;
    }

    function _getDecimals() internal pure virtual returns (uint256);

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
