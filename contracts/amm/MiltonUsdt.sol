// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Milton.sol";

contract MiltonUsdt is Milton {
    function getVersion() external pure virtual override returns (uint256) {
        return 9;
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }

    function _getMaxLeverage() internal view virtual override returns (uint256) {
        return 500000000000000000000;
    }

    function _getMaxLpUtilizationPerLegRate() internal view virtual override returns (uint256) {
        return 15000000000000000;
    }
}
