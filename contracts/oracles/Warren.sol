// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IWarren.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Constants} from "../libraries/Constants.sol";
import "../libraries/IporLogic.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IWarrenStorage.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";

import "./WarrenStorage.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract Warren is WarrenStorage, IWarren {
    using IporLogic for DataTypes.IPOR;

    constructor(address initialIporConfiguration)
        WarrenStorage(initialIporConfiguration)
    {}

    function getAssets() external view override returns (address[] memory) {
        return _assets;
    }

    function getIndex(address asset)
        external
        view
        override
        returns (
            uint256 indexValue,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 blockTimestamp
        )
    {
        DataTypes.IPOR memory iporIndex = _indexes[asset];

        return (
            indexValue = iporIndex.indexValue,
            ibtPrice = IporMath.division(
                iporIndex.quasiIbtPrice,
                Constants.YEAR_IN_SECONDS
            ),
            exponentialMovingAverage = iporIndex.exponentialMovingAverage,
            exponentialWeightedMovingVariance = iporIndex
                .exponentialWeightedMovingVariance,
            blockTimestamp = iporIndex.blockTimestamp
        );
    }

    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
        view
        override
        returns (DataTypes.AccruedIpor memory accruedIpor)
    {
        DataTypes.IPOR memory ipor = _indexes[asset];

        accruedIpor = DataTypes.AccruedIpor(
            ipor.indexValue,
            _calculateAccruedIbtPrice(calculateTimestamp, asset),
            ipor.exponentialMovingAverage,
            ipor.exponentialWeightedMovingVariance
        );
    }

    //@notice indexValue value with number of decimals like in asset
    function updateIndex(address asset, uint256 indexValue)
        external
        override
        onlyUpdater
    {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        address[] memory assets = new address[](1);
        assets[0] = asset;

        _updateIndexes(assets, indexes, block.timestamp);
    }

    function updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues
    ) external override onlyUpdater {
        _updateIndexes(assets, indexValues, block.timestamp);
    }

    function _updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues,
        uint256 updateTimestamp
    ) internal {
        require(
            assets.length == indexValues.length,
            IporErrors.WARREN_INPUT_ARRAYS_LENGTH_MISMATCH
        );
        uint256 i = 0;
        for (i; i != assets.length; i++) {
            //TODO:[gas-opt] Consider list asset supported as a part WarrenConfiguration - inherinted by WarrenStorage
            require(
                _iporConfiguration.assetSupported(assets[i]) == 1,
                IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
            );
            _updateIndex(assets[i], indexValues[i], updateTimestamp);
        }
    }

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        return _calculateAccruedIbtPrice(calculateTimestamp, asset);
    }

    function _calculateAccruedIbtPrice(
        uint256 calculateTimestamp,
        address asset
    ) internal view returns (uint256) {
        return
            IporMath.division(
                _indexes[asset].accrueQuasiIbtPrice(calculateTimestamp),
                Constants.YEAR_IN_SECONDS
            );
    }
}
