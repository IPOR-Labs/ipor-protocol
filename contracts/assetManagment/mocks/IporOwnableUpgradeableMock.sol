// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IporOwnableUpgradeable} from "../../security/IporOwnableUpgradeable.sol";

contract IporOwnableUpgradeableMock is IporOwnableUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
    }
}
