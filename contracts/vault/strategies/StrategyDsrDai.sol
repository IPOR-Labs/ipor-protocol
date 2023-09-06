// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/errors/AssetManagementErrors.sol";
import "../../libraries/math/IporMath.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../interfaces/dsr/IPot.sol";
import "../interfaces/dsr/ISavingsDai.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../../security/PauseManager.sol";
import "../../interfaces/IIporContractCommonGov.sol";

contract StrategyDsrDai is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
IStrategy,
    IProxyImplementation,
    IIporContractCommonGov
{
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant override getVersion = 2_000;

    address public immutable asset;
    address public immutable shareToken;
    address public immutable assetManagement;
    address public immutable pot;

    modifier onlyAssetManagement() {
        require(_msgSender() == assetManagement, AssetManagementErrors.CALLER_NOT_ASSET_MANAGEMENT);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address assetInput, address shareTokenInput, address assetManagementInput) {
        require(assetInput != address(0), IporErrors.WRONG_ADDRESS);
        require(shareTokenInput != address(0), IporErrors.WRONG_ADDRESS);
        require(assetManagementInput != address(0), IporErrors.WRONG_ADDRESS);

        asset = assetInput;
        shareToken = shareTokenInput;
        assetManagement = assetManagementInput;
        pot = ISavingsDai(shareTokenInput).pot();

        _disableInitializers();
    }

    function initialize() public initializer nonReentrant {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        IERC20Upgradeable(asset).safeApprove(shareToken, type(uint256).max);
    }

    function getApy() external view override returns (uint256 apy) {
        return IporMath.convertToWad(IporMath.rayPow(IPot(pot).dsr(), 365 days) - 1e27, 27);
    }

    function balanceOf() external view override returns (uint256) {
        uint256 shares = ISavingsDai(shareToken).balanceOf(address(this));
        return ISavingsDai(shareToken).convertToAssets(shares);
    }

    function deposit(
        uint256 wadAmount
    ) external override whenNotPaused onlyAssetManagement returns (uint256 depositedAmount) {
        IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), address(this), wadAmount);
        ISavingsDai(shareToken).deposit(wadAmount, address(this));
        depositedAmount = wadAmount;
    }

    function withdraw(
        uint256 wadAmount
    ) external override whenNotPaused onlyAssetManagement returns (uint256 withdrawnAmount) {
        ISavingsDai(shareToken).withdraw(wadAmount, _msgSender(), address(this));
        withdrawnAmount = wadAmount;
    }

    function pause() external override onlyOwner {
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
