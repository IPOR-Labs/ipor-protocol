// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IProxyImplementation {
    function getImplementation() external view returns (address);
}