// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/WarrenFacadeTypes.sol";

/// @title Interface frontend and other external systems for reading data from Warren smart contract.
interface IWarrenFacadeDataProvider {
    /// @notice Gets list of indexes.
    /// @return list of elements {WarrenFacadeTypes.IporFront} one element represents IPOR Index data for one specific asset.
    function getIndexes() external view returns (WarrenFacadeTypes.IporFront[] memory);
}
