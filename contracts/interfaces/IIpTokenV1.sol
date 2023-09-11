// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface to IpToken in version 1.
interface IIpTokenV1 {
    function setJoseph(address newRouter) external;

    function mint(address account, uint256 amount) external;
}
