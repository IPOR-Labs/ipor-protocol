// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;
import "./MockCaseBaseStanley.sol";

contract MockCase1Stanley is MockCaseBaseStanley {
    //solhint-disable no-empty-blocks
    constructor(address asset) MockCaseBaseStanley(asset) {}

}
