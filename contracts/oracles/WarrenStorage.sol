// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import { DataTypes } from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarrenStorage.sol";
import { Constants } from "../libraries/Constants.sol";
import { Errors } from "../Errors.sol";
import "../libraries/IporLogic.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IIporConfiguration.sol";

/**
 * @title Ipor Oracle Storage initial version
 * @author IPOR Labs
 */
//TODO: [gas-opt] use with Warren as inheritance
contract WarrenStorage is Ownable, IWarrenStorage {
    using IporLogic for DataTypes.IPOR;

    /// @notice event emitted when IPOR Index is updated by Updater
    event IporIndexUpdate(
        address asset,
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 exponentialMovingAverage,
        uint256 date
    );

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexUpdaterAdd(address updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexUpdaterRemove(address updater);

    /// @notice list of IPOR indexes for particular assets
    mapping(address => DataTypes.IPOR) public indexes;

    /// @notice list of assets used in indexes mapping
    address[] public assets;

    //TODO: [gas-optimisation] move to mapping(address => uint1) where in value = 1 then is updater if value = 0 then is not updater
    /// @notice list of addresses which has rights to modify indexes mapping
    address[] public updaters;

    IIporConfiguration private iporConfiguration;

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration)
        external
        onlyOwner
    {
        iporConfiguration = initialIporConfiguration;
    }

    function getAssets() external view override returns (address[] memory) {
        return assets;
    }

    function getIndex(address asset)
        external
        view
        override
        returns (DataTypes.IPOR memory)
    {
        return indexes[asset];
    }

    //@notice indexValues with decimals same like in asset
    function updateIndexes(
        address[] memory assetList,
        uint256[] memory indexValues,
        uint256 updateTimestamp
    ) external override onlyUpdater {
        require(
            assetList.length == indexValues.length,
            Errors.WARREN_INPUT_ARRAYS_LENGTH_MISMATCH
        );
        for (uint256 i = 0; i < assetList.length; i++) {
            //TODO:[gas-opt] Consider list asset supported as a part WarrenConfiguration - inherinted by WarrenStorage
            require(
                iporConfiguration.assetSupported(assetList[i]) == 1,
                Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
            );
            _updateIndex(assetList[i], indexValues[i], updateTimestamp);
        }
    }

    function addUpdater(address updater) external override onlyOwner {
        _addUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        require(updater != address(0), Errors.WARREN_WRONG_UPDATER_ADDRESS);
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == updater) {
                delete updaters[i];
                emit IporIndexUpdaterRemove(updater);
            }
        }
    }

    function getUpdaters() external view override returns (address[] memory) {
        return updaters;
    }

    function _addUpdater(address updater) internal {
        require(updater != address(0), Errors.WARREN_WRONG_UPDATER_ADDRESS);
        bool updaterExists = false;
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == updater) {
                updaterExists = true;
            }
        }
        if (!updaterExists) {
            updaters.push(updater);
            emit IporIndexUpdaterAdd(updater);
        }
    }

    function _updateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    ) internal onlyUpdater {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );

        bool assetExists = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == asset) {
                assetExists = true;
            }
        }

        uint256 newQuasiIbtPrice;
        uint256 newExponentialMovingAverage;

        if (!assetExists) {
            assets.push(asset);
            newQuasiIbtPrice = Constants.WAD_YEAR_IN_SECONDS;
            newExponentialMovingAverage = indexValue;
        } else {
            newQuasiIbtPrice = indexes[asset].accrueQuasiIbtPrice(
                updateTimestamp
            );
            newExponentialMovingAverage = IporLogic
                .calculateExponentialMovingAverage(
                    indexes[asset].exponentialMovingAverage,
                    indexValue,
                    iporAssetConfiguration.getDecayFactorValue()
                );
        }
        indexes[asset] = DataTypes.IPOR(
            asset,
            indexValue,
            newQuasiIbtPrice,
            newExponentialMovingAverage,
            updateTimestamp
        );
        emit IporIndexUpdate(
            asset,
            indexValue,
            newQuasiIbtPrice,
            newExponentialMovingAverage,
            updateTimestamp
        );
    }

    modifier onlyUpdater() {
        bool allowed = false;
        address[] memory _updaters = updaters;
        for (uint256 i = 0; i < _updaters.length; i++) {
            if (_updaters[i] == msg.sender) {
                allowed = true;
                break;
            }
        }
        require(allowed, Errors.WARREN_CALLER_NOT_WARREN_UPDATER);
        _;
    }
}
