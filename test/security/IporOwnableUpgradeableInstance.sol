// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@ipor-protocol/contracts/security/IporOwnableUpgradeable.sol";

contract IporOwnableUpgradeableInstance is IporOwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
    }
}
