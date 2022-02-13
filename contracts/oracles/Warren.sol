// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IWarren.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Constants} from "../libraries/Constants.sol";
import "../libraries/IporLogic.sol";
import {IporMath} from "../libraries/IporMath.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract Warren is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IWarren
{
    using SafeCast for uint256;
    using IporLogic for DataTypes.IPOR;

    uint256 private constant _DECAY_FACTOR_VALUE = 1e17;

    mapping(address => uint256) internal _updaters;
	
    mapping(address => DataTypes.IPOR) internal _indexes;

    modifier onlyUpdater() {
        require(
            _updaters[msg.sender] == 1,
            IporErrors.WARREN_CALLER_NOT_WARREN_UPDATER
        );
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
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
        DataTypes.IPOR memory ipor = _indexes[asset];
        require(
            ipor.quasiIbtPrice >= Constants.WAD_YEAR_IN_SECONDS,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );
        return (
            indexValue = ipor.indexValue,
            ibtPrice = IporMath.division(
                ipor.quasiIbtPrice,
                Constants.YEAR_IN_SECONDS
            ),
            exponentialMovingAverage = ipor.exponentialMovingAverage,
            exponentialWeightedMovingVariance = ipor
                .exponentialWeightedMovingVariance,
            blockTimestamp = ipor.blockTimestamp
        );
    }

    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
        view
        override
        returns (DataTypes.AccruedIpor memory accruedIpor)
    {
        DataTypes.IPOR memory ipor = _indexes[asset];
        require(
            ipor.quasiIbtPrice >= Constants.WAD_YEAR_IN_SECONDS,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        accruedIpor = DataTypes.AccruedIpor(
            ipor.indexValue,
            _calculateAccruedIbtPrice(calculateTimestamp, asset),
            ipor.exponentialMovingAverage,
            ipor.exponentialWeightedMovingVariance
        );
    }

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        return _calculateAccruedIbtPrice(calculateTimestamp, asset);
    }

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

    function addAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indexes[asset].quasiIbtPrice < Constants.WAD_YEAR_IN_SECONDS,
            IporErrors.MILTON_CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS
        );
        _indexes[asset] = DataTypes.IPOR(
            0,
            0,
            Constants.WAD_YEAR_IN_SECONDS.toUint128(),
            0,
            0
        );
        emit IporIndexAddAsset(asset);
    }

    function removeAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indexes[asset].quasiIbtPrice >= Constants.WAD_YEAR_IN_SECONDS,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );
        delete _indexes[asset];
        emit IporIndexRemoveAsset(asset);
    }

    function addUpdater(address updater) external override onlyOwner {
        _updaters[updater] = 1;
        emit IporIndexAddUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        _updaters[updater] = 0;
        emit IporIndexRemoveUpdater(updater);
    }

	function isUpdater(address updater) external view override returns(uint256) {
		return _updaters[updater];
	}

    function _updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues,
        uint256 updateTimestamp
    ) internal onlyUpdater {
        require(
            assets.length == indexValues.length,
            IporErrors.WARREN_INPUT_ARRAYS_LENGTH_MISMATCH
        );
        uint256 i = 0;
        for (i; i != assets.length; i++) {
            _updateIndex(assets[i], indexValues[i], updateTimestamp);
        }
    }

    function _updateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    ) internal {
        DataTypes.IPOR memory ipor = _indexes[asset];
        require(
            ipor.quasiIbtPrice >= Constants.WAD_YEAR_IN_SECONDS,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        uint256 newQuasiIbtPrice;
        uint256 newExponentialMovingAverage;
        uint256 newExponentialWeightedMovingVariance;

        if (ipor.indexValue == 0) {
            newQuasiIbtPrice = Constants.WAD_YEAR_IN_SECONDS;
            newExponentialMovingAverage = indexValue;
        } else {
            newQuasiIbtPrice = ipor.accrueQuasiIbtPrice(updateTimestamp);
            newExponentialMovingAverage = IporLogic
                .calculateExponentialMovingAverage(
                    ipor.exponentialMovingAverage,
                    indexValue,
                    _DECAY_FACTOR_VALUE
                );
            newExponentialWeightedMovingVariance = IporLogic
                .calculateExponentialWeightedMovingVariance(
                    ipor.exponentialWeightedMovingVariance,
                    newExponentialMovingAverage,
                    indexValue,
                    _DECAY_FACTOR_VALUE
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

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
