// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./Warren.sol";
import "../interfaces/IIporAssetConfiguration.sol";

contract TestWarren is Warren {

    function test_updateIndex(address asset, uint256 indexValue, uint256 updateTimestamp) external onlyUpdater {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        address[] memory assets = new address[](1);
        assets[0] = asset;
        IWarrenStorage(_addressesManager.getWarrenStorage()).updateIndexes(assets, indexes, updateTimestamp);
    }

    function test_updateIndexes(address[] memory assets, uint256[] memory indexValues, uint256 updateTimestamp) external onlyUpdater {
        IWarrenStorage(_addressesManager.getWarrenStorage()).updateIndexes(assets, indexValues, updateTimestamp);
    }

}
