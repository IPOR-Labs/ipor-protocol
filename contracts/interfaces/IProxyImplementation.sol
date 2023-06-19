// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IProxyImplementation {
    /// @notice Retrieves the address of the implementation contract for UUPS proxy.
    /// @return The address of the implementation contract.
    /// @dev The function returns the value stored in the implementation storage slot.
    function getImplementation() external view returns (address);
}