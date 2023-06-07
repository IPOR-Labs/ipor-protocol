// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

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
import "../libraries/Constants.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAssetManagement.sol";
import "../security/IporOwnableUpgradeable.sol";

contract AmmTreasury is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmTreasury
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _assetManagement;
    address internal immutable _router;

    constructor(
        address asset,
        uint256 decimals,
        address ammStorage,
        address assetManagement,
        address router
    ) {
        require(asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " asset address cannot be 0"));
        require(ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " AMM storage address cannot be 0"));
        require(assetManagement != address(0), string.concat(IporErrors.WRONG_ADDRESS, " asset management address cannot be 0"));
        require(router != address(0), string.concat(IporErrors.WRONG_ADDRESS, " router address cannot be 0"));

        _asset = asset;
        _decimals = decimals;
        _ammStorage = ammStorage;
        _assetManagement = assetManagement;
        _router = router;

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

    modifier onlyRouter() {
        require(_msgSender() == _router, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    function getConfiguration()
        external
        view
        override
        returns (
            address asset,
            uint256 decimals,
            address ammStorage,
            address assetManagement,
            address router
        )
    {
        return (_asset, _decimals, _ammStorage, _assetManagement, _router);
    }

    function getVersion() external pure returns (uint256) {
        return 2_000;
    }

    /// @notice Joseph deposits to AssetManagement asset amount from AmmTreasury.
    /// @param assetAmount underlying token amount represented in 18 decimals
    function depositToAssetManagementInternal(uint256 assetAmount) external onlyRouter nonReentrant whenNotPaused {
        (uint256 vaultBalance, uint256 depositedAmount) = IAssetManagement(_assetManagement).deposit(assetAmount);
        IAmmStorage(_ammStorage).updateStorageWhenDepositToAssetManagement(depositedAmount, vaultBalance);
    }

    //@param assetAmount underlying token amount represented in 18 decimals
    function withdrawFromAssetManagementInternal(uint256 assetAmount) external nonReentrant onlyRouter whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = IAssetManagement(_assetManagement).withdraw(assetAmount);
        IAmmStorage(_ammStorage).updateStorageWhenWithdrawFromAssetManagement(withdrawnAmount, vaultBalance);
    }

    function withdrawAllFromAssetManagementInternal() external nonReentrant onlyRouter whenNotPaused {
        (uint256 withdrawnAmount, uint256 vaultBalance) = IAssetManagement(_assetManagement).withdrawAll();
        IAmmStorage(_ammStorage).updateStorageWhenWithdrawFromAssetManagement(withdrawnAmount, vaultBalance);
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

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
