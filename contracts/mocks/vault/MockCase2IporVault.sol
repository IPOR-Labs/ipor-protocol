// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockCaseBaseIporVault.sol";
import "../../libraries/IporMath.sol";

contract MockCase2IporVault is MockCaseBaseIporVault {
    constructor(address asset) MockCaseBaseIporVault(asset) {}

    function _getCurrentInterest() internal pure override returns (uint256) {
        return 3e18;
    }

    //@dev withdraw 80%
    function _withdrawPercentage() internal pure override returns (uint256) {
        return 8e17;
    }
}
