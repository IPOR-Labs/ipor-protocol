// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IProxyImplementation.sol";
import "../libraries/Constants.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "../security/PauseManager.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./interfaces/IAmmTreasuryEth.sol";

contract AmmTreasuryEth is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IAmmTreasuryEth,
    IProxyImplementation
{
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public immutable stEth;
    address public immutable router;

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(_msgSender()), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyRouter() {
        require(_msgSender() == router, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    constructor(address stEthInput, address routerInput) {
        stEth = stEthInput.checkAddress();
        router = routerInput.checkAddress();

        _disableInitializers();
    }

    function initialize(bool paused) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        if (paused) {
            _pause();
        } else {
            IERC20Upgradeable(stEth).forceApprove(router, Constants.MAX_VALUE);
        }
    }

    function getConfiguration() external view override returns (address, address) {
        return (stEth, router);
    }

    function getVersion() external pure returns (uint256) {
        return 2_000;
    }

    function pause() external override onlyPauseGuardian {
        IERC20Upgradeable(stEth).safeApprove(router, 0);
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
        IERC20Upgradeable(stEth).forceApprove(router, Constants.MAX_VALUE);
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
