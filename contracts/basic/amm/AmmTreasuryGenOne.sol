// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../interfaces/IAmmTreasuryGenOne.sol";
import "../interfaces/IAmmStorageGenOne.sol";
import "../../libraries/Constants.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/IporContractValidator.sol";
import "../../security/PauseManager.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../types/StorageTypesGenOne.sol";

contract AmmTreasuryGenOne is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmTreasuryGenOne,
    IProxyImplementation
{
    using SafeCast for uint256;
    using SafeCast for int256;
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable asset;
    address public immutable router;
    address public immutable ammStorage;

    modifier onlyPauseGuardian() {
        if (!PauseManager.isPauseGuardian(msg.sender)) {
            revert IporErrors.CallerNotPauseGuardian(IporErrors.CALLER_NOT_PAUSE_GUARDIAN, msg.sender);
        }
        _;
    }

    modifier onlyRouter() {
        if (msg.sender != router) {
            revert IporErrors.CallerNotIporProtocolRouter(IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER, msg.sender);
        }
        _;
    }

    constructor(address assetInput, address routerInput, address ammStorageInput) {
        asset = assetInput.checkAddress();
        router = routerInput.checkAddress();
        ammStorage = ammStorageInput.checkAddress();

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
        AmmTypesGenOne.Balance memory balance = IAmmStorageGenOne(ammStorage).getBalance();

        uint256 liquidityPool = (IERC20Upgradeable(asset).balanceOf(address(this)).toInt256() -
            balance.totalCollateralPayFixed.toInt256() -
            balance.totalCollateralReceiveFixed.toInt256() -
            balance.iporPublicationFee.toInt256() -
            balance.treasury.toInt256()).toUint256();

        return liquidityPool;
    }

    function getVersion() external pure returns (uint256) {
        return 2_001;
    }

    function pause() external override onlyPauseGuardian {
        IERC20Upgradeable(asset).safeApprove(router, 0);
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
