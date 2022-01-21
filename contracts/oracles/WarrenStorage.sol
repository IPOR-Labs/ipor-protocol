// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarrenStorage.sol";
import {Constants} from "../libraries/Constants.sol";
import {IporErrors} from "../IporErrors.sol";
import "../libraries/IporLogic.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IIporConfiguration.sol";

/**
 * @title Ipor Oracle Storage initial version
 * @author IPOR Labs
 */
//TODO: [gas-opt] use with Warren as inheritance
contract WarrenStorage is Ownable, Pausable, IWarrenStorage {
    using IporLogic for DataTypes.IPOR;

    /// @notice event emitted when IPOR Index is updated by Updater
    event IporIndexUpdate(
        address asset,
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 exponentialMovingAverage,
        uint256 newExponentialWeightedMovingVariance,
        uint256 date
    );

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexUpdaterAdd(address updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexUpdaterRemove(address updater);

    IIporConfiguration private _iporConfiguration;

    /// @notice list of assets used in indexes mapping
    address[] internal _assets;
    mapping(address => bool) internal _assetsMap;

    /// @notice list of addresses which has rights to modify indexes mapping
    address[] internal _updaters;
    mapping(address => bool) internal _updatersMap;

    /// @notice list of IPOR indexes for particular assets
    mapping(address => DataTypes.IPOR) internal _indexes;

    constructor(address initialIporConfiguration) {
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function addUpdater(address updater) external override onlyOwner {
        _addUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        require(updater != address(0), IporErrors.WARREN_WRONG_UPDATER_ADDRESS);
		uint256 i = 0;
		uint256 updatersLength = _updaters.length;
        for (i; i != updatersLength; i++) {
            if (_updaters[i] == updater) {
                _updatersMap[updater] = false;
                delete _updaters[i];
                emit IporIndexUpdaterRemove(updater);
            }
        }
    }

    function getUpdaters() external view override returns (address[] memory) {
        return _updaters;
    }

    function _addUpdater(address updater) internal {
        require(updater != address(0), IporErrors.WARREN_WRONG_UPDATER_ADDRESS);

        if (!_updatersMap[updater]) {
            _updatersMap[updater] = true;
            _updaters.push(updater);
            emit IporIndexUpdaterAdd(updater);
        }
    }

    function _updateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    ) internal onlyUpdater {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );

        uint256 newQuasiIbtPrice;
        uint256 newExponentialMovingAverage;
        uint256 newExponentialWeightedMovingVariance;
        // uint256 power = IporMath.division((updateTimestamp-indexes[asset].blockTimestamp)*Constants.D18, iporAssetConfiguration.getDecayFactorValue());
        // uint256 alpha = IporMath.division(Constants.D18, Constants.E_VALUE ** power);
        //TODO: figure out how to calculate alpha???
        //TODO: move this const to Warren internally - dont use iporassetconfiguration in warren
        uint256 alpha = iporAssetConfiguration.getDecayFactorValue();

        if (!_assetsMap[asset]) {
            _assetsMap[asset] = true;
            _assets.push(asset);
            newQuasiIbtPrice = Constants.WAD_YEAR_IN_SECONDS;
            newExponentialMovingAverage = indexValue;
            newExponentialWeightedMovingVariance = 0;
        } else {
			DataTypes.IPOR memory ipor = _indexes[asset];

            newQuasiIbtPrice = ipor.accrueQuasiIbtPrice(
                updateTimestamp
            );

            newExponentialMovingAverage = IporLogic
                .calculateExponentialMovingAverage(
                    ipor.exponentialMovingAverage,
                    indexValue,
                    alpha
                );

            newExponentialWeightedMovingVariance = IporLogic
                .calculateExponentialWeightedMovingVariance(
                    ipor.exponentialWeightedMovingVariance,
                    newExponentialMovingAverage,
                    indexValue,
                    alpha
                );
        }
        _indexes[asset] = DataTypes.IPOR(
            uint32(updateTimestamp),
            uint128(indexValue),
            uint128(newQuasiIbtPrice),
            uint128(newExponentialMovingAverage),
            uint128(newExponentialWeightedMovingVariance)
        );
        emit IporIndexUpdate(
            asset,
            indexValue,
            newQuasiIbtPrice,
            newExponentialMovingAverage,
            newExponentialWeightedMovingVariance,
            updateTimestamp
        );
    }

    modifier onlyUpdater() {
        require(
            _updatersMap[msg.sender],
            IporErrors.WARREN_CALLER_NOT_WARREN_UPDATER
        );
        _;
    }
}
