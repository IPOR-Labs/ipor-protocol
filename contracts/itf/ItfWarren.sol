// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../oracles/Warren.sol";
import "../interfaces/IIporAssetConfiguration.sol";

contract ItfWarren is Warren {
    constructor(address initialIporConfiguration)
        Warren(initialIporConfiguration)
    {}

    function itfUpdateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    ) external onlyUpdater {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        address[] memory assets = new address[](1);
        assets[0] = asset;
        IWarrenStorage(_iporConfiguration.getWarrenStorage()).updateIndexes(
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
        IWarrenStorage(_iporConfiguration.getWarrenStorage()).updateIndexes(
            assets,
            indexValues,
            updateTimestamp
        );
    }
}
