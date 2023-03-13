// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Milton.sol";

contract MiltonUsdc is Milton {
    function getVersion() external pure virtual override returns (uint256) {
        return 8;
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }

    function _getMaxLeverage() internal view virtual override returns (uint256) {
        return 500 * 1e18;
    }

    function _getMaxLpUtilizationPerLegRate() internal view virtual override returns (uint256) {
        return 25 * 1e15;
    }
}
