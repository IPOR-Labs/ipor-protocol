// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IDsrManager {
    function daiBalance(address usr) external returns (uint256 wad);

    // wad is denominated in dai
    function join(address dst, uint256 wad) external;

    // wad is denominated in dai
    function exit(address dst, uint256 wad) external;

    function exitAll(address dst) external;
}
