// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./IporOracle.sol";

contract TestIporOracleProxy is IporOracle {

    function test_updateIndex(string memory asset, uint256 indexValue, uint256 updateTimestamp) public {
        _updateIndex(asset, indexValue, updateTimestamp);
    }

    function test_updateIndexes(string[] memory _assets, uint256[] memory indexValues, uint256 updateTimestamp) public {
        _updateIndexes(_assets, indexValues, updateTimestamp);
    }

}