// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "./types/IporOracleFacadeTypes.sol";

/// @title Interface frontend and other external systems for reading data from IporOracle smart contract.
interface IIporOracleFacadeDataProvider {
    /// @notice Returns current version of IporOracle Facade Data Provider
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current IporOracle Facade Data Provider version
    function getVersion() external pure returns (uint256);

    /// @notice Gets list of indexes.
    /// @return list of elements {IporOracleFacadeTypes.IporFront} one element represents IPOR Index data for one specific asset.
    function getIndexes() external view returns (IporOracleFacadeTypes.IporFront[] memory);
}
