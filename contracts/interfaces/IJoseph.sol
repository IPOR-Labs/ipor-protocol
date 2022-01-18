// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IJoseph {
    function provideLiquidity(uint256 liquidityAmount) external;

    function redeem(uint256 ipTokenVolume) external;
}
