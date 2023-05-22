// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
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
import "../interfaces/IIporAlgorithm.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/IporLogic.sol";
import "../libraries/math/InterestRates.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract IporOracle is Initializable, PausableUpgradeable, UUPSUpgradeable, IporOwnableUpgradeable, IIporOracle {
    using SafeCast for uint256;
    using IporLogic for IporOracleTypes.IPOR;

    address internal immutable _usdc;
    uint256 internal immutable _usdcInitialIbtPrice;
    address internal immutable _usdt;
    uint256 internal immutable _usdtInitialIbtPrice;
    address internal immutable _dai;
    uint256 internal immutable _daiInitialIbtPrice;

    mapping(address => uint256) internal _updaters;
    mapping(address => IporOracleTypes.IPOR) internal _indexes;
    address internal _iporAlgorithmFacade;

    modifier onlyUpdater() {
        require(_updaters[_msgSender()] == 1, IporOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address usdc,
        uint256 usdcInitialIbtPrice,
        address usdt,
        uint256 usdtInitialIbtPrice,
        address dai,
        uint256 daiInitialIbtPrice
    ) {
        _disableInitializers();

        _usdc = usdc;
        _usdcInitialIbtPrice = usdcInitialIbtPrice;
        _usdt = usdt;
        _usdtInitialIbtPrice = usdtInitialIbtPrice;
        _dai = dai;
        _daiInitialIbtPrice = daiInitialIbtPrice;
    }

    function initialize(address[] memory assets, uint32[] memory updateTimestamps) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        for (uint256 i; i != assetsLength; ++i) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);

            _indexes[assets[i]] = IporOracleTypes.IPOR(
                0,
                0,
                updateTimestamps[i]
            );
        }
    }

    function postUpgrade(address[] memory assets) public onlyOwner {
        uint256 assetsLength = assets.length;

        for (uint256 i; i != assetsLength; ++i) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            IporOracleTypes.IPOR memory oldIpor = _indexes[assets[i]];
            _indexes[assets[i]] = IporOracleTypes.IPOR(0, oldIpor.indexValue, block.timestamp.toUint32());
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 4;
    }

    function getIndex(address asset)
        external
        view
        override
        returns (
            uint256 indexValue,
            uint256 ibtPrice,
            uint256 lastUpdateTimestamp
        )
    {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        return (
            indexValue = ipor.indexValue,
            ibtPrice = _calculateAccruedIbtPrice(asset, ipor, ipor.lastUpdateTimestamp),
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
        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        accruedIpor = IporTypes.AccruedIpor(
            ipor.indexValue,
            _calculateAccruedIbtPrice(asset, ipor, calculateTimestamp),
            0,
            0
        );
    }

    function getIporAlgorithmFacade() external view override returns (address) {
        return _iporAlgorithmFacade;
    }

    function setIporAlgorithmFacade(address newIporAlgorithmFacade) external onlyOwner {
        require(newIporAlgorithmFacade != address(0), IporErrors.WRONG_ADDRESS);
        address oldIporAlgorithmFacade = _iporAlgorithmFacade;
        _iporAlgorithmFacade = newIporAlgorithmFacade;
        emit IporAlgorithmFacadeChanged(_msgSender(), oldIporAlgorithmFacade, newIporAlgorithmFacade);
    }

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        return _calculateAccruedIbtPrice(asset, _indexes[asset], calculateTimestamp);
    }

    function updateIndex(address asset, uint256 indexValue) external override onlyUpdater whenNotPaused {
        _updateIndex(asset, indexValue, block.timestamp);
    }

    function updateIndex(address asset)
        external
        override
        onlyUpdater
        whenNotPaused
        returns (IporTypes.AccruedIpor memory accruedIpor)
    {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];

        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        address iporAlgorithmFacade = _iporAlgorithmFacade;

        require(iporAlgorithmFacade != address(0), IporOracleErrors.IPOR_ALGORITHM_ADDRESS_NOT_SET);

        uint256 newIndexValue = IIporAlgorithm(iporAlgorithmFacade).calculateIpor(asset);

        (accruedIpor.indexValue, accruedIpor.ibtPrice, ) = _updateIndex(asset, newIndexValue, block.timestamp);
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

    function addAsset(address asset, uint256 updateTimestamp) external override onlyOwner whenNotPaused {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indexes[asset].quasiIbtPrice == 0, IporOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS);
        _indexes[asset] = IporOracleTypes.IPOR(
            0,
            0,
            updateTimestamp.toUint32()
        );
        emit IporIndexAddAsset(asset, updateTimestamp);
    }

    function removeAsset(address asset) external override onlyOwner whenNotPaused {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indexes[asset].lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);
        delete _indexes[asset];
        emit IporIndexRemoveAsset(asset);
    }

    function isAssetSupported(address asset) external view override returns (bool) {
        return _indexes[asset].lastUpdateTimestamp > 0;
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
    ) internal {
        require(assets.length == indexValues.length, IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH);

        for (uint256 i; i != assets.length; ++i) {
            _updateIndex(assets[i], indexValues[i], updateTimestamp);
        }
    }

    function _updateIndex(
        address asset,
        uint256 indexValue,
        uint256 updateTimestamp
    )
        internal
        returns (
            uint256 newIndexValue,
            uint256 newIbtPrice,
            uint256 lastUpdateTimestamp
        )
    {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];

        require(ipor.lastUpdateTimestamp > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        require(
            ipor.lastUpdateTimestamp <= updateTimestamp,
            IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );

        uint256 newQuasiIbtPrice = ipor.accrueQuasiIbtPrice(updateTimestamp);

        _indexes[asset] = IporOracleTypes.IPOR(
            newQuasiIbtPrice.toUint128(),
            indexValue.toUint64(),
            updateTimestamp.toUint32()
        );

        newIndexValue = indexValue;
        newIbtPrice = IporMath.division(newQuasiIbtPrice, Constants.YEAR_IN_SECONDS);
        lastUpdateTimestamp = updateTimestamp;

        emit IporIndexUpdate(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
    }

    function _calculateAccruedIbtPrice(
        address asset,
        IporOracleTypes.IPOR memory ipor,
        uint256 calculateTimestamp
    ) internal view returns (uint256) {
        uint256 initialIbtPrice = _getInitialIbtPrice(asset);
        uint256 interestRateMultipliedByTime = IporMath.division(
            ipor.accrueQuasiIbtPrice(calculateTimestamp),
            Constants.YEAR_IN_SECONDS
        );
        return
            InterestRates.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                initialIbtPrice,
                interestRateMultipliedByTime
            );
    }

    function _getInitialIbtPrice(address asset) internal view returns (uint256) {
        if (asset == _usdc) {
            return _usdcInitialIbtPrice;
        } else if (asset == _usdt) {
            return _usdtInitialIbtPrice;
        } else if (asset == _dai) {
            return _daiInitialIbtPrice;
        }
        return Constants.D18;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
