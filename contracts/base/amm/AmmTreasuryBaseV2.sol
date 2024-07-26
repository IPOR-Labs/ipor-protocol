// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {StorageSlotUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import {IporMath} from "../../libraries/math/IporMath.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../interfaces/IAmmTreasuryBaseV2.sol";
import "../interfaces/IAmmStorageBaseV1.sol";
import "../../libraries/Constants.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/IporContractValidator.sol";
import "../../security/PauseManager.sol";
import "../../security/IporOwnableUpgradeable.sol";

/// @title AMM Treasury Base V2 support Asset Management which is ERC4626 Vault.
contract AmmTreasuryBaseV2 is
Initializable,
PausableUpgradeable,
ReentrancyGuardUpgradeable,
UUPSUpgradeable,
IporOwnableUpgradeable,
IAmmTreasuryBaseV2,
IProxyImplementation
{
    using SafeCast for uint256;
    using SafeCast for int256;
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable asset;
    uint256 public immutable assetDecimals;
    address public immutable router;
    address public immutable ammStorage;
    address public immutable ammAssetManagement;

    modifier onlyPauseGuardian() {
        if (!PauseManager.isPauseGuardian(msg.sender)) {
            revert IporErrors.CallerNotPauseGuardian(IporErrors.CALLER_NOT_PAUSE_GUARDIAN, msg.sender);
        }
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == router, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    constructor(address asset_, address router_, address ammStorage_, address ammAssetManagement_) {
        asset = asset_.checkAddress();
        assetDecimals = IERC20Metadata(asset).decimals();
        router = router_.checkAddress();
        ammStorage = ammStorage_.checkAddress();
        ammAssetManagement = ammAssetManagement_.checkAddress();

        /// @dev pool asset must match the underlying asset in the AmmAssetManagement vault
        address ammAssetManagementAsset = IERC4626(ammAssetManagement).asset();
        if (ammAssetManagementAsset != asset) {
            revert IporErrors.AssetMismatch(ammAssetManagementAsset, asset);
        }

        _disableInitializers();
    }

    function initialize(bool paused) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        if (paused) {
            _pause();
        } else {
            IERC20Upgradeable(asset).forceApprove(router, Constants.MAX_VALUE);
        }
    }

    function getLiquidityPoolBalance() external view override returns (uint256) {
        AmmTypesBaseV1.Balance memory balance = IAmmStorageBaseV1(ammStorage).getBalance();

        return
            (IporMath.convertToWad(IERC20Upgradeable(asset).balanceOf(address(this)), assetDecimals).toInt256() +
                (IporMath.convertToWad(IERC4626(ammAssetManagement).maxWithdraw(address(this)), assetDecimals))
                    .toInt256() -
                balance.totalCollateralPayFixed.toInt256() -
                balance.totalCollateralReceiveFixed.toInt256() -
                balance.iporPublicationFee.toInt256() -
                balance.treasury.toInt256() -
                balance.totalLiquidationDepositBalance.toInt256()).toUint256();
    }

    function depositToAssetManagementInternal(
        uint256 wadAssetAmount
    ) external override onlyRouter nonReentrant whenNotPaused {
        uint256 assetAmount = IporMath.convertWadToAssetDecimals(wadAssetAmount, assetDecimals);
        IERC20Upgradeable(asset).forceApprove(ammAssetManagement, assetAmount);
        IERC4626(ammAssetManagement).deposit(assetAmount, address(this));
    }

    function withdrawFromAssetManagementInternal(
        uint256 wadAssetAmount
    ) external override onlyRouter nonReentrant whenNotPaused {
        IERC4626(ammAssetManagement).withdraw(
            IporMath.convertWadToAssetDecimals(wadAssetAmount, assetDecimals),
            address(this),
            address(this)
        );
    }

    function withdrawAllFromAssetManagementInternal() external override onlyRouter nonReentrant whenNotPaused {
        IERC4626(ammAssetManagement).redeem(
            IERC4626(ammAssetManagement).balanceOf(address(this)),
            address(this),
            address(this)
        );
    }

    function getVersion() external pure returns (uint256) {
        return 2_003;
    }

    function pause() external override onlyPauseGuardian {
        IERC20Upgradeable(asset).forceApprove(router, 0);
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
        IERC20Upgradeable(asset).forceApprove(router, Constants.MAX_VALUE);
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
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
