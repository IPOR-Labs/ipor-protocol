// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IMarketSafetyOracle.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/MarketSafetyOracleStorageTypes.sol";
import "../libraries/errors/MarketSafetyOracleErrors.sol";

/**
 * @title Market Safety Oracle contract
 *
 * @author IPOR Labs
 */
contract MarketSafetyOracle is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IMarketSafetyOracle
{
    using SafeCast for uint256;

    mapping(address => uint256) internal _updaters;
    mapping(address => MarketSafetyOracleStorageTypes.MarketSafetyIndicatorsStorage) internal _indicators;

    modifier onlyUpdater() {
        require(_updaters[_msgSender()] == 1, MarketSafetyOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory assets) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        for (uint256 i; i != assetsLength; ++i) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);

            _indicators[assets[i]] = MarketSafetyOracleStorageTypes.MarketSafetyIndicatorsStorage(
                0,
                0,
                0,
                0,
                0,
                block.timestamp.toUint32()
            );
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    function getIndicators(address asset)
        external
        view
        override
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRate,
            uint256 lastUpdateTimestamp
        )
    {
        MarketSafetyOracleStorageTypes.MarketSafetyIndicatorsStorage memory indicators = _indicators[asset];
        require(indicators.maxNotionalPayFixed > 0, MarketSafetyOracleErrors.ASSET_NOT_SUPPORTED);
        return (
            indicators.maxNotionalPayFixed * 1e22, // 1 = 10k notional
            indicators.maxNotionalReceiveFixed * 1e22,
            indicators.maxUtilizationRatePayFixed * 1e14, // 1 = 0.01%
            indicators.maxUtilizationRateReceiveFixed * 1e14,
            indicators.maxUtilizationRate * 1e14,
            indicators.lastUpdateTimestamp
        );
    }

    function updateIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) external override onlyUpdater whenNotPaused {
        _updateIndicators(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate
        );
    }

    function updateIndicators(
        address[] memory asset,
        uint256[] memory maxNotionalPayFixed,
        uint256[] memory maxNotionalReceiveFixed,
        uint256[] memory maxUtilizationRatePayFixed,
        uint256[] memory maxUtilizationRateReceiveFixed,
        uint256[] memory maxUtilizationRate
    ) external override onlyUpdater whenNotPaused {
        uint256 assetsLength = asset.length;

        require(
            assetsLength == maxNotionalPayFixed.length &&
                assetsLength == maxNotionalReceiveFixed.length &&
                assetsLength == maxUtilizationRatePayFixed.length &&
                assetsLength == maxUtilizationRateReceiveFixed.length &&
                assetsLength == maxUtilizationRate.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        for (uint256 i; i != assetsLength; ++i) {
            _updateIndicators(
                asset[i],
                maxNotionalPayFixed[i],
                maxNotionalReceiveFixed[i],
                maxUtilizationRatePayFixed[i],
                maxUtilizationRateReceiveFixed[i],
                maxUtilizationRate[i]
            );
        }
    }

    function _updateIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) internal {
        MarketSafetyOracleStorageTypes.MarketSafetyIndicatorsStorage memory indicators = _indicators[asset];

        require(indicators.maxNotionalPayFixed > 0, MarketSafetyOracleErrors.ASSET_NOT_SUPPORTED);

        _indicators[asset] = MarketSafetyOracleStorageTypes.MarketSafetyIndicatorsStorage(
            maxNotionalPayFixed.toUint64(),
            maxNotionalReceiveFixed.toUint64(),
            maxUtilizationRatePayFixed.toUint16(),
            maxUtilizationRateReceiveFixed.toUint16(),
            maxUtilizationRate.toUint16(),
            block.timestamp.toUint32()
        );

        emit MarketSafetyIndicatorsUpdate(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate
        );
    }

    function addAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indicators[asset].maxNotionalPayFixed == 0,
            MarketSafetyOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS
        );

        _indicators[asset] = MarketSafetyOracleStorageTypes.MarketSafetyIndicatorsStorage(
            0,
            0,
            0,
            0,
            0,
            block.timestamp.toUint32()
        );

        emit MarketSafetyAddAsset(asset);
    }

    function removeAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indicators[asset].maxNotionalPayFixed > 0, MarketSafetyOracleErrors.ASSET_NOT_SUPPORTED);

        delete _indicators[asset];
        emit MarketSafetyRemoveAsset(asset);
    }

    function isAssetSupported(address asset) external view override returns (bool) {
        return _indicators[asset].maxNotionalPayFixed > 0;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function addUpdater(address updater) external override onlyOwner {
        require(updater != address(0), IporErrors.WRONG_ADDRESS);

        _updaters[updater] = 1;
        emit MarketSafetyAddUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        require(updater != address(0), IporErrors.WRONG_ADDRESS);

        _updaters[updater] = 0;
        emit MarketSafetyRemoveUpdater(updater);
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
