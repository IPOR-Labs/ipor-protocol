// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/WarrenFacadeTypes.sol";

interface IWarrenFacadeDataProvider {
    function getIndexes() external view returns (WarrenFacadeTypes.IporFront[] memory);
}
