// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import "../../contracts/security/IporOwnableUpgradeable.sol";

contract IporOwnableUpgradeableInstance is IporOwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
    }
}
