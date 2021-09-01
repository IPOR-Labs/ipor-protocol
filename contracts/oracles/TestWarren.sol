// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./Warren.sol";

contract TestWarren is Warren {

    constructor(address warrenStorageAddr) Warren(warrenStorageAddr){}

    function test_updateIndex(string memory asset, uint256 indexValue, uint256 updateTimestamp) public onlyUpdater {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        string[] memory assets = new string[](1);
        assets[0] = asset;
        warrenStorage.updateIndexes(assets, indexes, updateTimestamp);
    }

    function test_updateIndexes(string[] memory assets, uint256[] memory indexValues, uint256 updateTimestamp) public onlyUpdater {
        warrenStorage.updateIndexes(assets, indexValues, updateTimestamp);
    }

    function setupInitialValues(address updater) public {
        warrenStorage.setupInitialValues(updater);
    }
}