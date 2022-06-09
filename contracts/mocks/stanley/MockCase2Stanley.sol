// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;
import "./MockCaseBaseStanley.sol";

contract MockCase2Stanley is MockCaseBaseStanley {
    //solhint-disable no-empty-blocks
    constructor(address asset) MockCaseBaseStanley(asset) {}

    function _getCurrentInterest() internal pure override returns (uint256) {
        return 3e18;
    }

    //@dev withdraw 80%
    function _withdrawRate() internal pure override returns (uint256) {
        return 8e17;
    }
}
