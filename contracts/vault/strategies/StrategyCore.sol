// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@ipor-protocol/contracts/interfaces/IStrategy.sol";
import "@ipor-protocol/contracts/interfaces/IProxyImplementation.sol";
import "@ipor-protocol/contracts/libraries/errors/IporErrors.sol";
import "@ipor-protocol/contracts/libraries/errors/AssetManagementErrors.sol";
import "@ipor-protocol/contracts/security/IporOwnableUpgradeable.sol";
import "@ipor-protocol/contracts/security/PauseManager.sol";

abstract contract StrategyCore is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStrategy,
    IProxyImplementation
{
    address internal _asset;
    address internal _shareToken;
    address internal _assetManagement;
    address internal _treasury;
    address internal _treasuryManager;

    modifier onlyAssetManagement() {
        require(_msgSender() == _assetManagement, AssetManagementErrors.CALLER_NOT_ASSET_MANAGEMENT);
        _;
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyTreasuryManager() {
        require(_msgSender() == _treasuryManager, AssetManagementErrors.CALLER_NOT_TREASURY_MANAGER);
        _;
    }

    function getVersion() external pure override returns (uint256) {
        return 2_000;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    /**
     * @dev Share token to track _asset (DAI -> cDAI)
     */
    function getShareToken() external view override returns (address) {
        return _shareToken;
    }

    function getAssetManagement() external view override returns (address) {
        return _assetManagement;
    }

    function setAssetManagement(address newAssetManagement) external whenNotPaused onlyOwner {
        require(newAssetManagement != address(0), IporErrors.WRONG_ADDRESS);
        _assetManagement = newAssetManagement;
        emit AssetManagementChanged(newAssetManagement);
    }

    function getTreasuryManager() external view override returns (address) {
        return _treasuryManager;
    }

    function setTreasuryManager(address manager) external whenNotPaused onlyOwner {
        require(manager != address(0), IporErrors.WRONG_ADDRESS);
        _treasuryManager = manager;
        emit TreasuryManagerChanged(manager);
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function setTreasury(address newTreasury) external whenNotPaused onlyTreasuryManager {
        require(newTreasury != address(0), AssetManagementErrors.INCORRECT_TREASURY_ADDRESS);
        _treasury = newTreasury;
        emit TreasuryChanged(newTreasury);
    }

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addPauseGuardian(address _guardian) external onlyOwner {
        PauseManager.addPauseGuardian(_guardian);
    }

    function removePauseGuardian(address _guardian) external onlyOwner {
        PauseManager.removePauseGuardian(_guardian);
    }
}
