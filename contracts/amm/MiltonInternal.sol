// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/Constants.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IStanley.sol";
import "./libraries/IporSwapLogic.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/types/AmmMiltonTypes.sol";

abstract contract MiltonInternal is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IMiltonInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for IporTypes.IporSwapMemory;


    /// @dev 0 means 0%, 1e18 means 100%, represented in 18 decimals
    uint256 internal constant _OPENING_FEE_RATE = 5e14;

    uint256 internal constant _LIQUIDATION_LEG_LIMIT = 10;

    address internal _asset;
    address internal _joseph;
    IStanley internal _stanley;
    IIporOracle internal _iporOracle;
    IMiltonStorage internal _miltonStorage;
    IMiltonSpreadModel internal _miltonSpreadModel;

    uint32 internal _autoUpdateIporIndexThreshold;

    mapping(address => bool) internal _swapLiquidators;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IIporRiskManagementOracle private immutable _iporRiskManagementOracle;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) {
        require(iporRiskManagementOracle != address(0), IporErrors.WRONG_ADDRESS);

        /// @custom:oz-upgrades-unsafe-allow state-variable-assignment
        _iporRiskManagementOracle = IIporRiskManagementOracle(iporRiskManagementOracle);
    }

    modifier onlyJoseph() {
        require(_msgSender() == _getJoseph(), MiltonErrors.CALLER_NOT_JOSEPH);
        _;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getIporOracle() external view returns (address) {
        return address(_iporOracle);
    }

    function getMiltonStorage() external view returns (address) {
        return address(_miltonStorage);
    }

    function getStanley() external view returns (address) {
        return address(_stanley);
    }

    function getRiskManagementOracle() external view returns (address) {
        return address(_iporRiskManagementOracle);
    }

    function calculateSoapAtTimestamp(uint256 calculateTimestamp)
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _calculateSoap(calculateTimestamp);
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function calculatePayoffPayFixed(IporTypes.IporSwapMemory memory swap) external view override returns (int256) {
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, block.timestamp);
        return swap.calculatePayoffPayFixed(block.timestamp, accruedIbtPrice);
    }

    function calculatePayoffReceiveFixed(IporTypes.IporSwapMemory memory swap) external view override returns (int256) {
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, block.timestamp);
        return swap.calculatePayoffReceiveFixed(block.timestamp, accruedIbtPrice);
    }

    /// @notice Joseph deposits to Stanley asset amount from Milton.
    /// @param assetAmount underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetAmount) external onlyJoseph nonReentrant whenNotPaused {
        (uint256 vaultBalance, uint256 depositedAmount) = _getStanley().deposit(assetAmount);
        _getMiltonStorage().updateStorageWhenDepositToStanley(depositedAmount, vaultBalance);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetAmount) external nonReentrant onlyJoseph whenNotPaused {
        _withdrawFromStanley(assetAmount);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function _withdrawFromStanley(uint256 assetAmount) internal {
        (uint256 withdrawnAmount, uint256 vaultBalance) = _getStanley().withdraw(assetAmount);
        _getMiltonStorage().updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function withdrawAllFromStanley() external nonReentrant onlyJoseph whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = _getStanley().withdrawAll();
        _getMiltonStorage().updateStorageWhenWithdrawFromStanley(withdrawnAmount, vaultBalance);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setupMaxAllowanceForAsset(address spender) external override onlyOwner whenNotPaused {
        IERC20Upgradeable(_asset).safeIncreaseAllowance(spender, Constants.MAX_VALUE);
    }

    function setJoseph(address newJoseph) external override onlyOwner whenNotPaused {
        require(newJoseph != address(0), IporErrors.WRONG_ADDRESS);
        address oldJoseph = _getJoseph();
        _joseph = newJoseph;
        emit JosephChanged(_msgSender(), oldJoseph, newJoseph);
    }

    function getJoseph() external view override returns (address) {
        return _getJoseph();
    }

    function setMiltonSpreadModel(address newMiltonSpreadModel) external override onlyOwner whenNotPaused {
        require(newMiltonSpreadModel != address(0), IporErrors.WRONG_ADDRESS);
        address oldMiltonSpreadModel = address(_miltonSpreadModel);
        _miltonSpreadModel = IMiltonSpreadModel(newMiltonSpreadModel);
        emit MiltonSpreadModelChanged(_msgSender(), oldMiltonSpreadModel, newMiltonSpreadModel);
    }

    function getMiltonSpreadModel() external view override returns (address) {
        return address(_miltonSpreadModel);
    }

    function _getDecimals() internal view virtual returns (uint256);


    function _getLiquidationLegLimit() internal view virtual returns (uint256) {
        return _LIQUIDATION_LEG_LIMIT;
    }

    function _getJoseph() internal view virtual returns (address) {
        return _joseph;
    }

    function _getIporOracle() internal view virtual returns (IIporOracle) {
        return _iporOracle;
    }

    function _getMiltonStorage() internal view virtual returns (IMiltonStorage) {
        return _miltonStorage;
    }

    function _getStanley() internal view virtual returns (IStanley) {
        return _stanley;
    }


    function _calculateSoap(uint256 calculateTimestamp)
        internal
        view
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        uint256 accruedIbtPrice = _getIporOracle().calculateAccruedIbtPrice(_asset, calculateTimestamp);
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _getMiltonStorage().calculateSoap(
            accruedIbtPrice,
            calculateTimestamp
        );
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }
}
