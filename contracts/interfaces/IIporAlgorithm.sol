// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

/// @title Interface for interaction with IPOR calculation algorithm.
interface IIporAlgorithm {
    /// @notice Returns current version of IPOR algorithm.
    /// @return Current IPOR algorithm version.
    function getVersion() external pure returns (uint256);

    /// @notice Calculates IPOR index by given asset address
    /// @param asset Asset address
    /// @return iporIndex IPOR index value represented in 18 decimals
    function calculateIpor(address asset) external view returns (uint256 iporIndex);
}
