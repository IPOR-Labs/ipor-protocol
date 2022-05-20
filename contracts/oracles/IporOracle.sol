// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/IporOracleErrors.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/IporOracleTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIporOracle.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/IporLogic.sol";
import "./libraries/DecayFactorCalculation.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract IporOracle is UUPSUpgradeable, IporOwnableUpgradeable, PausableUpgradeable, IIporOracle {
    using SafeCast for uint256;
    using IporLogic for IporOracleTypes.IPOR;

    mapping(address => uint256) internal _updaters;

    mapping(address => IporOracleTypes.IPOR) internal _indexes;

    modifier onlyUpdater() {
        require(_updaters[_msgSender()] == 1, IporOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    function initialize(
        address[] memory assets,
        uint32[] memory updateTimestamps,
        uint64[] memory exponentialMovingAverages,
        uint64[] memory exponentialWeightedMovingVariances
    ) public initializer {
        __Ownable_init();

        uint256 assetsLength = assets.length;

        for (uint256 i = 0; i != assetsLength; i++) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);

            _indexes[assets[i]] = IporOracleTypes.IPOR(
                Constants.WAD_YEAR_IN_SECONDS.toUint128(),
                exponentialMovingAverages[i],
                exponentialWeightedMovingVariances[i],
                0,
                updateTimestamps[i]
            );
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
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
            uint256 lastUpdateTimestamp
        )
    {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.quasiIbtPrice != 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        return (
            indexValue = ipor.indexValue,
            ibtPrice = IporMath.division(ipor.quasiIbtPrice, Constants.YEAR_IN_SECONDS),
            exponentialMovingAverage = ipor.exponentialMovingAverage,
            exponentialWeightedMovingVariance = ipor.exponentialWeightedMovingVariance,
            lastUpdateTimestamp = ipor.lastUpdateTimestamp
        );
    }

    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
        view
        virtual
        override
        returns (IporTypes.AccruedIpor memory accruedIpor)
    {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.quasiIbtPrice != 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        accruedIpor = IporTypes.AccruedIpor(
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
        whenNotPaused
    {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        address[] memory assets = new address[](1);
        assets[0] = asset;

        _updateIndexes(assets, indexes, block.timestamp);
    }

    function updateIndexes(address[] memory assets, uint256[] memory indexValues)
        external
        override
        onlyUpdater
        whenNotPaused
    {
        _updateIndexes(assets, indexValues, block.timestamp);
    }

    function addUpdater(address updater) external override onlyOwner whenNotPaused {
        _updaters[updater] = 1;
        emit IporIndexAddUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner whenNotPaused {
        _updaters[updater] = 0;
        emit IporIndexRemoveUpdater(updater);
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    function addAsset(
        address asset,
        uint256 updateTimestamp,
        uint256 exponentialMovingAverage,
        uint256 exponentialWeightedMovingVariance
    ) external override onlyOwner whenNotPaused {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indexes[asset].quasiIbtPrice == 0,
            IporOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS
        );
        _indexes[asset] = IporOracleTypes.IPOR(
            Constants.WAD_YEAR_IN_SECONDS.toUint128(),
            exponentialMovingAverage.toUint64(),
            exponentialWeightedMovingVariance.toUint64(),
            0,
            updateTimestamp.toUint32()
        );
        emit IporIndexAddAsset(
            asset,
            exponentialMovingAverage,
            exponentialWeightedMovingVariance,
            updateTimestamp
        );
    }

    function removeAsset(address asset) external override onlyOwner whenNotPaused {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indexes[asset].quasiIbtPrice != 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        delete _indexes[asset];
        emit IporIndexRemoveAsset(asset);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues,
        uint256 updateTimestamp
    ) internal onlyUpdater {
        require(assets.length == indexValues.length, IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH);

        for (uint256 i = 0; i != assets.length; i++) {
            _updateIndex(assets[i], indexValues[i], updateTimestamp);
        }
    }

    function _updateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    ) internal {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.quasiIbtPrice != 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        require(
            ipor.lastUpdateTimestamp <= updateTimestamp,
            IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );

        uint256 newExponentialMovingAverage = IporLogic.calculateExponentialMovingAverage(
            ipor.exponentialMovingAverage,
            indexValue,
            _decayFactorValue(updateTimestamp - ipor.lastUpdateTimestamp)
        );

        uint256 newExponentialWeightedMovingVariance = IporLogic
            .calculateExponentialWeightedMovingVariance(
                ipor.exponentialWeightedMovingVariance,
                newExponentialMovingAverage,
                indexValue,
                _decayFactorValue(updateTimestamp - ipor.lastUpdateTimestamp)
            );

        uint256 newQuasiIbtPrice = ipor.accrueQuasiIbtPrice(updateTimestamp);

        _indexes[asset] = IporOracleTypes.IPOR(
            newQuasiIbtPrice.toUint128(),
            newExponentialMovingAverage.toUint64(),
            newExponentialWeightedMovingVariance.toUint64(),
            indexValue.toUint64(),
            updateTimestamp.toUint32()
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

    function _decayFactorValue(uint256 timeFromLastPublication)
        internal
        pure
        virtual
        returns (uint256)
    {
        return DecayFactorCalculation.calculate(timeFromLastPublication);
    }

    function _calculateAccruedIbtPrice(uint256 calculateTimestamp, address asset)
        internal
        view
        returns (uint256)
    {
        return
            IporMath.division(
                _indexes[asset].accrueQuasiIbtPrice(calculateTimestamp),
                Constants.YEAR_IN_SECONDS
            );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
