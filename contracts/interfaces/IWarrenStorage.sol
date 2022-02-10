// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IWarrenStorage {
    function pause() external;

    function unpause() external;

    function addUpdater(address updater) external;

    function removeUpdater(address updater) external;

    function getUpdaters() external view returns (address[] memory);
}
