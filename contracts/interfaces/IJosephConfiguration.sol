// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJosephConfiguration {
    function decimals() external view returns (uint8);

    function asset() external view returns (address);
}
