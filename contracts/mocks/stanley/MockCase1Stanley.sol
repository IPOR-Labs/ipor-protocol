// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import "./MockCaseBaseStanley.sol";

contract MockCase1Stanley is MockCaseBaseStanley {
    constructor(address asset) MockCaseBaseStanley(asset) {}

    function _getCurrentInterest() internal pure override returns (uint256) {
        return 3e18;
    }
}
