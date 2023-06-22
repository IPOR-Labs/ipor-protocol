// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@ipor-protocol/contracts/router/AccessControl.sol";
import "@ipor-protocol/contracts/interfaces/IProxyImplementation.sol";

/// @dev for testing purposes
contract EmptyRouterImplementation is UUPSUpgradeable, AccessControl, IProxyImplementation {
    function initialize(bool paused) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
