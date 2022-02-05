// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarrenStorage.sol";
import {Constants} from "../libraries/Constants.sol";
import {IporErrors} from "../IporErrors.sol";
import "../libraries/IporLogic.sol";

/**
 * @title Ipor Oracle Storage initial version
 * @author IPOR Labs
 */
contract WarrenStorage is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IWarrenStorage
{
    using SafeCast for uint256;
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

    uint256 private constant DECAY_FACTOR_VALUE = 1e17;

    /// @notice list of assets used in indexes mapping
    address[] internal _assets;
    mapping(address => bool) internal _assetsMap;
    mapping(address => uint256) internal _supportedAssets;

    /// @notice list of addresses which has rights to modify indexes mapping
    address[] internal _updaters;
    mapping(address => bool) internal _updatersMap;

    /// @notice list of IPOR indexes for particular assets
    mapping(address => DataTypes.IPOR) internal _indexes;

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

    function _authorizeUpgrade(address) internal override onlyOwner {}

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
        uint256 newQuasiIbtPrice;
        uint256 newExponentialMovingAverage;
        uint256 newExponentialWeightedMovingVariance;

        if (!_assetsMap[asset]) {
            _assetsMap[asset] = true;
            _assets.push(asset);
            newQuasiIbtPrice = Constants.WAD_YEAR_IN_SECONDS;
            newExponentialMovingAverage = indexValue;
            newExponentialWeightedMovingVariance = 0;
        } else {
            DataTypes.IPOR memory ipor = _indexes[asset];

            newQuasiIbtPrice = ipor.accrueQuasiIbtPrice(updateTimestamp);

            newExponentialMovingAverage = IporLogic
                .calculateExponentialMovingAverage(
                    ipor.exponentialMovingAverage,
                    indexValue,
                    DECAY_FACTOR_VALUE
                );

            newExponentialWeightedMovingVariance = IporLogic
                .calculateExponentialWeightedMovingVariance(
                    ipor.exponentialWeightedMovingVariance,
                    newExponentialMovingAverage,
                    indexValue,
                    DECAY_FACTOR_VALUE
                );
        }
        _indexes[asset] = DataTypes.IPOR(
            updateTimestamp.toUint32(),
            indexValue.toUint128(),
            newQuasiIbtPrice.toUint128(),
            newExponentialMovingAverage.toUint128(),
            newExponentialWeightedMovingVariance.toUint128()
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
