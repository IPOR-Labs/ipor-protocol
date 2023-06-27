// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for Mock Proxy
interface IMockProxy {
    function upgradeTo(address newImplementation) external;

}
