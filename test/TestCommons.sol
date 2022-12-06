// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/Test.sol";

contract TestCommons is Test {
    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }
}
