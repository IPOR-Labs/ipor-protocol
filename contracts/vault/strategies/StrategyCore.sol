// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/AssetManagementErrors.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../../security/PauseManager.sol";
import "../../interfaces/IStrategyDsr.sol";
import "../../libraries/IporContractValidator.sol";

abstract contract StrategyCore is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IStrategy,
    IStrategyDsr,
    IProxyImplementation
{
    using IporContractValidator for address;
    address public immutable asset;
    uint256 public immutable assetDecimals;
    address public immutable shareToken;
    address public immutable assetManagement;

    /// @dev deprecated
    address internal _assetDeprecated;
    /// @dev deprecated
    address internal _shareTokenDeprecated;
    /// @dev deprecated
    address internal _assetManagementDeprecated;

    address internal _treasury;
    address internal _treasuryManager;

    modifier onlyAssetManagement() {
        require(_msgSender() == assetManagement, AssetManagementErrors.CALLER_NOT_ASSET_MANAGEMENT);
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

    constructor(address assetInput, uint256 assetDecimalsInput, address shareTokenInput, address assetManagementInput) {
        asset = assetInput.checkAddress();

        require(assetDecimalsInput == IERC20MetadataUpgradeable(assetInput).decimals(), IporErrors.WRONG_DECIMALS);

        assetDecimals = assetDecimalsInput;
        shareToken = shareTokenInput.checkAddress();
        assetManagement = assetManagementInput.checkAddress();
    }

    function getVersion() external pure override returns (uint256) {
        return 2_000;
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

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardian(address guardian) external override onlyOwner {
        PauseManager.addPauseGuardian(guardian);
    }

    function removePauseGuardian(address guardian) external override onlyOwner {
        PauseManager.removePauseGuardian(guardian);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
