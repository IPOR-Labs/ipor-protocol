// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "./DataTypesContract.sol";

interface AaveLendingPool {
    function deposit(address reserve, uint256 amount, uint16 referralCode) external;

    function getReserveData(address reserve) external view returns (DataTypesContract.ReserveData memory);
}
