// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/DarcyTypes.sol";

interface IWarrenDarcyDataProvider {
    function getIndexes() external view returns (DarcyTypes.IporFront[] memory);
}
