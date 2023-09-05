// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAssetManagement.sol";
import "../interfaces/IProxyImplementation.sol";
import "../libraries/Constants.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "../security/PauseManager.sol";
import "../security/IporOwnableUpgradeable.sol";

contract AmmTreasury is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmTreasury,
    IProxyImplementation
{
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _assetManagement;
    address internal immutable _router;

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyRouter() {
        require(_msgSender() == _router, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    constructor(address asset, uint256 decimals, address ammStorage, address assetManagement, address router) {
        _asset = asset.checkAddress();
        _decimals = decimals;
        _ammStorage = ammStorage.checkAddress();
        _assetManagement = assetManagement.checkAddress();
        _router = router.checkAddress();

        _disableInitializers();
    }

    /// @notice Initialize the contract
    /// @param paused If true, the contract will be paused after initialization
    /// @dev WARNING! AmmTreasury has deprecated storage fields that are not used in V2.
    /// @dev Before reusing those slots, clear them in the initialize function.
    /// @dev List of removed fields:
    ///  - address _asset
    ///  - address _joseph
    ///  - address _assetManagement
    ///  - address _iporOracle
    ///  - address _ammStorage
    ///  - address _ammTreasurySpreadModel
    ///  - uint32 _autoUpdateIporIndexThreshold
    ///  - mapping(address => bool) _swapLiquidators
    function initialize(bool paused) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        if (paused) {
            _pause();
        }
    }

    function getConfiguration()
        external
        view
        override
        returns (address asset, uint256 decimals, address ammStorage, address assetManagement, address router)
    {
        return (_asset, _decimals, _ammStorage, _assetManagement, _router);
    }

    function getVersion() external pure returns (uint256) {
        return 2_000;
    }

    /// @notice Joseph deposits to AssetManagement asset amount from AmmTreasury.
    /// @param wadAssetAmount underlying token amount represented in 18 decimals
    function depositToAssetManagementInternal(uint256 wadAssetAmount) external onlyRouter nonReentrant whenNotPaused {
        (uint256 vaultBalance, uint256 depositedAmount) = IAssetManagement(_assetManagement).deposit(wadAssetAmount);
        IAmmStorage(_ammStorage).updateStorageWhenDepositToAssetManagement(depositedAmount, vaultBalance);
    }

    //@param wadAssetAmount underlying token amount represented in 18 decimals
    function withdrawFromAssetManagementInternal(uint256 wadAssetAmount) external nonReentrant onlyRouter whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = IAssetManagement(_assetManagement).withdraw(wadAssetAmount);
        IAmmStorage(_ammStorage).updateStorageWhenWithdrawFromAssetManagement(withdrawnAmount, vaultBalance);
    }

    function withdrawAllFromAssetManagementInternal() external nonReentrant onlyRouter whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = IAssetManagement(_assetManagement).withdrawAll();
        IAmmStorage(_ammStorage).updateStorageWhenWithdrawFromAssetManagement(withdrawnAmount, vaultBalance);
    }

    function grandMaxAllowanceForSpender(address spender) external override onlyOwner {
        IERC20Upgradeable(_asset).forceApprove(spender, Constants.MAX_VALUE);
    }

    function revokeAllowanceForSpender(address spender) external override onlyOwner {
        IERC20Upgradeable(_asset).safeApprove(spender, 0);
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

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
