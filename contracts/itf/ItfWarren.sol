// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../oracles/Warren.sol";

contract ItfWarren is Warren {

	function itfGetDecayFactorValue() external pure returns(uint256) {
		return _DECAY_FACTOR_VALUE;
	}

    function itfUpdateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    ) external onlyUpdater {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        address[] memory assets = new address[](1);
        assets[0] = asset;
        _updateIndexes(
            assets,
            indexes,
            updateTimestamp
        );
    }

    function itfUpdateIndexes(
        address[] memory assets,
        uint256[] memory indexValues,
        uint256 updateTimestamp
    ) external onlyUpdater {
        _updateIndexes(
            assets,
            indexValues,
            updateTimestamp
        );
    }
	
}
