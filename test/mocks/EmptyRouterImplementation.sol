// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/router/AccessControl.sol";

/// @dev for testing purposes
contract EmptyRouterImplementation is UUPSUpgradeable, AccessControl {
    function initialize(bool paused) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
