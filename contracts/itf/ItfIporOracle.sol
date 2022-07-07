// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../oracles/IporOracle.sol";

contract ItfIporOracle is IporOracle {
    uint256 _decayFactor;

    function itfGetDecayFactorValue(uint256 timeFromLastPublication)
        external
        view
        returns (uint256)
    {
        return _decayFactorValue(timeFromLastPublication);
    }

    function setDecayFactor(uint256 decayFactor) external onlyOwner {
        _decayFactor = decayFactor;
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
        _updateIndexes(assets, indexes, updateTimestamp);
    }

    function itfUpdateIndexes(
        address[] memory assets,
        uint256[] memory indexValues,
        uint256 updateTimestamp
    ) external onlyUpdater {
        _updateIndexes(assets, indexValues, updateTimestamp);
    }

    function _decayFactorValue(uint256 timeFromLastPublication)
        internal
        view
        override
        returns (uint256)
    {
        if (_decayFactor != 0) {
            return _decayFactor;
        }
        return DecayFactorCalculation.calculate(timeFromLastPublication);
    }
}
