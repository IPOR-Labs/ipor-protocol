// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface AaveLendingPoolProviderV2 {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address);
}
