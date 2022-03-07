// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockCaseBaseStanley.sol";
import "../../libraries/IporMath.sol";

contract MockCase0Stanley is MockCaseBaseStanley {
    constructor(address asset) MockCaseBaseStanley(asset) {}
}
