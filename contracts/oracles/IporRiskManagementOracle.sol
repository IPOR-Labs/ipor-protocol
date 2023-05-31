// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/IporRiskManagementOracleStorageTypes.sol";
import "../libraries/errors/IporRiskManagementOracleErrors.sol";
import "../libraries/Constants.sol";

/**
 * @title Ipor Risk Management Oracle contract
 *
 * @author IPOR Labs
 */
contract IporRiskManagementOracle is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IIporRiskManagementOracle
{
    using SafeCast for uint256;
    using SafeCast for int256;

    mapping(address => uint256) internal _updaters;
    mapping(address => IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage) internal _indicators;
    mapping(address => IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage)
        internal _baseSpreadsAndFixedRateCaps;

    modifier onlyUpdater() {
        require(_updaters[_msgSender()] == 1, IporRiskManagementOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] memory assets,
        IporRiskManagementOracleTypes.RiskIndicators[] calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[] calldata baseSpreadsAndFixedRateCaps
    ) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        require(
            assetsLength == riskIndicators.length && assetsLength == baseSpreadsAndFixedRateCaps.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        for (uint256 i; i != assetsLength; ++i) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            _indicators[assets[i]] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
                riskIndicators[i].maxNotionalPayFixed.toUint64(),
                riskIndicators[i].maxNotionalReceiveFixed.toUint64(),
                riskIndicators[i].maxUtilizationRatePayFixed.toUint16(),
                riskIndicators[i].maxUtilizationRateReceiveFixed.toUint16(),
                riskIndicators[i].maxUtilizationRate.toUint16(),
                block.timestamp.toUint32()
            );

            emit RiskIndicatorsUpdated(
                assets[i],
                riskIndicators[i].maxNotionalPayFixed,
                riskIndicators[i].maxNotionalReceiveFixed,
                riskIndicators[i].maxUtilizationRatePayFixed,
                riskIndicators[i].maxUtilizationRateReceiveFixed,
                riskIndicators[i].maxUtilizationRate
            );

            _baseSpreadsAndFixedRateCaps[assets[i]] = IporRiskManagementOracleStorageTypes
                .BaseSpreadsAndFixedRateCapsStorage(
                    block.timestamp.toUint32(),
                    baseSpreadsAndFixedRateCaps[i].spread28dPayFixed.toInt24(),
                    baseSpreadsAndFixedRateCaps[i].spread28dReceiveFixed.toInt24(),
                    baseSpreadsAndFixedRateCaps[i].spread60dPayFixed.toInt24(),
                    baseSpreadsAndFixedRateCaps[i].spread60dReceiveFixed.toInt24(),
                    baseSpreadsAndFixedRateCaps[i].spread90dPayFixed.toInt24(),
                    baseSpreadsAndFixedRateCaps[i].spread90dReceiveFixed.toInt24(),
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap28dPayFixed.toUint16(),
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap28dReceiveFixed.toUint16(),
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap60dPayFixed.toUint16(),
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap60dReceiveFixed.toUint16(),
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap90dPayFixed.toUint16(),
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap90dReceiveFixed.toUint16()
                );

            emit BaseSpreadsUpdated(
                assets[i],
                baseSpreadsAndFixedRateCaps[i].spread28dPayFixed,
                baseSpreadsAndFixedRateCaps[i].spread28dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].spread60dPayFixed,
                baseSpreadsAndFixedRateCaps[i].spread60dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].spread90dPayFixed,
                baseSpreadsAndFixedRateCaps[i].spread90dReceiveFixed
            );

            emit FixedRateCapsUpdated(
                assets[i],
                baseSpreadsAndFixedRateCaps[i].fixedRateCap28dPayFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap28dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap60dPayFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap60dReceiveFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap90dPayFixed,
                baseSpreadsAndFixedRateCaps[i].fixedRateCap90dReceiveFixed
            );
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
    }

    function getOpenSwapParameters(
        address asset,
        uint256 direction,
        uint256 duration
    )
        external
        view
        override
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxUtilizationRatePerLeg,
            uint256 maxUtilizationRate,
            int256 spread,
            uint256 fixedRateCap
        )
    {
        (maxNotionalPerLeg, maxUtilizationRatePerLeg, maxUtilizationRate) = _getRiskIndicatorsPerLeg(asset, direction);
        (spread, fixedRateCap) = _getSpread(asset, direction, duration);
        return (
            maxNotionalPerLeg,
            maxUtilizationRatePerLeg,
            maxUtilizationRate,
            spread * Constants.D12_INT,
            fixedRateCap * Constants.D12
        );
    }

    function _getRiskIndicatorsPerLeg(address asset, uint256 direction)
        internal
        view
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxUtilizationRatePerLeg,
            uint256 maxUtilizationRate
        )
    {
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRateBothLegs,

        ) = _getRiskIndicators(asset);

        if (direction == 0) {
            return (maxNotionalPayFixed, maxUtilizationRatePayFixed, maxUtilizationRateBothLegs);
        } else {
            return (maxNotionalReceiveFixed, maxUtilizationRateReceiveFixed, maxUtilizationRateBothLegs);
        }
    }

    function _getSpread(
        address asset,
        uint256 direction,
        uint256 duration
    ) internal view returns (int256 spread, uint256 fixedRateCap) {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _baseSpreadsAndFixedRateCaps[asset];
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        if (duration == 0) {
            if (direction == 0) {
                return (
                    baseSpreadsAndFixedRateCaps.spread28dPayFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed
                );
            } else {
                return (
                    baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed
                );
            }
        } else if (duration == 1) {
            if (direction == 0) {
                return (
                    baseSpreadsAndFixedRateCaps.spread60dPayFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed
                );
            } else {
                return (
                    baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed
                );
            }
        } else {
            if (direction == 0) {
                return (
                    baseSpreadsAndFixedRateCaps.spread90dPayFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed
                );
            } else {
                return (
                    baseSpreadsAndFixedRateCaps.spread90dReceiveFixed,
                    baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
                );
            }
        }
    }

    function getRiskIndicators(address asset)
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
        return _getRiskIndicators(asset);
    }

    function _getRiskIndicators(address asset)
        internal
        view
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxUtilizationRatePayFixed,
            uint256 maxUtilizationRateReceiveFixed,
            uint256 maxUtilizationRate,
            uint256 lastUpdateTimestamp
        )
    {
        IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage memory indicators = _indicators[asset];
        require(indicators.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);
        return (
            uint256(indicators.maxNotionalPayFixed) * 1e22, // 1 = 10k notional
            uint256(indicators.maxNotionalReceiveFixed) * 1e22,
            uint256(indicators.maxUtilizationRatePayFixed) * 1e14, // 1 = 0.01%
            uint256(indicators.maxUtilizationRateReceiveFixed) * 1e14,
            uint256(indicators.maxUtilizationRate) * 1e14,
            uint256(indicators.lastUpdateTimestamp)
        );
    }

    function getBaseSpreads(address asset)
        external
        view
        override
        returns (
            uint256 lastUpdateTimestamp,
            int256 spread28dPayFixed,
            int256 spread28dReceiveFixed,
            int256 spread60dPayFixed,
            int256 spread60dReceiveFixed,
            int256 spread90dPayFixed,
            int256 spread90dReceiveFixed
        )
    {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _baseSpreadsAndFixedRateCaps[asset];
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );
        return (
            uint256(baseSpreadsAndFixedRateCaps.lastUpdateTimestamp),
            int256(baseSpreadsAndFixedRateCaps.spread28dPayFixed) * Constants.D12_INT, // 1 = 0.01%
            int256(baseSpreadsAndFixedRateCaps.spread28dReceiveFixed) * Constants.D12_INT,
            int256(baseSpreadsAndFixedRateCaps.spread60dPayFixed) * Constants.D12_INT,
            int256(baseSpreadsAndFixedRateCaps.spread60dReceiveFixed) * Constants.D12_INT,
            int256(baseSpreadsAndFixedRateCaps.spread90dPayFixed) * Constants.D12_INT,
            int256(baseSpreadsAndFixedRateCaps.spread90dReceiveFixed) * Constants.D12_INT
        );
    }

    function getFixedRateCaps(address asset)
        external
        view
        override
        returns (
            uint256 lastUpdateTimestamp,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        )
    {
        return _getFixedRateCaps(asset);
    }

    function _getFixedRateCaps(address asset)
        internal
        view
        returns (
            uint256 lastUpdateTimestamp,
            uint256 fixedRateCap28dPayFixed,
            uint256 fixedRateCap28dReceiveFixed,
            uint256 fixedRateCap60dPayFixed,
            uint256 fixedRateCap60dReceiveFixed,
            uint256 fixedRateCap90dPayFixed,
            uint256 fixedRateCap90dReceiveFixed
        )
    {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _baseSpreadsAndFixedRateCaps[asset];
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );
        return (
            uint256(baseSpreadsAndFixedRateCaps.lastUpdateTimestamp),
            uint256(baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed) * Constants.D12, // 1 = 0.01%
            uint256(baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed) * Constants.D12,
            uint256(baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed) * Constants.D12,
            uint256(baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed) * Constants.D12,
            uint256(baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed) * Constants.D12,
            uint256(baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed) * Constants.D12
        );
    }

    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) external override onlyUpdater whenNotPaused {
        _updateRiskIndicators(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate
        );
    }

    function updateRiskIndicators(
        address[] calldata asset,
        uint256[] calldata maxNotionalPayFixed,
        uint256[] calldata maxNotionalReceiveFixed,
        uint256[] calldata maxUtilizationRatePayFixed,
        uint256[] calldata maxUtilizationRateReceiveFixed,
        uint256[] calldata maxUtilizationRate
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
            _updateRiskIndicators(
                asset[i],
                maxNotionalPayFixed[i],
                maxNotionalReceiveFixed[i],
                maxUtilizationRatePayFixed[i],
                maxUtilizationRateReceiveFixed[i],
                maxUtilizationRate[i]
            );
        }
    }

    function _updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) internal {
        IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage memory indicators = _indicators[asset];

        require(indicators.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        _indicators[asset] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
            maxNotionalPayFixed.toUint64(),
            maxNotionalReceiveFixed.toUint64(),
            maxUtilizationRatePayFixed.toUint16(),
            maxUtilizationRateReceiveFixed.toUint16(),
            maxUtilizationRate.toUint16(),
            block.timestamp.toUint32()
        );

        emit RiskIndicatorsUpdated(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            maxUtilizationRate
        );
    }

    function updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external override onlyUpdater whenNotPaused {
        _updateBaseSpreadsAndFixedRateCaps(asset, baseSpreadsAndFixedRateCaps);
    }

    function updateBaseSpreadsAndFixedRateCaps(
        address[] memory asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[] calldata baseSpreadsAndFixedRateCaps
    ) external override onlyUpdater whenNotPaused {
        uint256 assetsLength = asset.length;

        require(assetsLength == baseSpreadsAndFixedRateCaps.length, IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH);

        for (uint256 i; i != assetsLength; ++i) {
            _updateBaseSpreadsAndFixedRateCaps(asset[i], baseSpreadsAndFixedRateCaps[i]);
        }
    }

    function _updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) internal {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCapsStorage = _baseSpreadsAndFixedRateCaps[asset];

        require(
            baseSpreadsAndFixedRateCapsStorage.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        _baseSpreadsAndFixedRateCaps[asset] = IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
            block.timestamp.toUint32(),
            baseSpreadsAndFixedRateCaps.spread28dPayFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread28dReceiveFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread60dPayFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread60dReceiveFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread90dPayFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread90dReceiveFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed.toUint16()
        );

        emit BaseSpreadsUpdated(
            asset,
            baseSpreadsAndFixedRateCaps.spread28dPayFixed,
            baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
            baseSpreadsAndFixedRateCaps.spread60dPayFixed,
            baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
            baseSpreadsAndFixedRateCaps.spread90dPayFixed,
            baseSpreadsAndFixedRateCaps.spread90dReceiveFixed
        );

        emit FixedRateCapsUpdated(
            asset,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
        );
    }

    function addAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indicators[asset].lastUpdateTimestamp == 0,
            IporRiskManagementOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS
        );

        _indicators[asset] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
            riskIndicators.maxNotionalPayFixed.toUint64(),
            riskIndicators.maxNotionalReceiveFixed.toUint64(),
            riskIndicators.maxUtilizationRatePayFixed.toUint16(),
            riskIndicators.maxUtilizationRateReceiveFixed.toUint16(),
            riskIndicators.maxUtilizationRate.toUint16(),
            block.timestamp.toUint32()
        );

        _baseSpreadsAndFixedRateCaps[asset] = IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
            block.timestamp.toUint32(),
            baseSpreadsAndFixedRateCaps.spread28dPayFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread28dReceiveFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread60dPayFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread60dReceiveFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread90dPayFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.spread90dReceiveFixed.toInt24(),
            baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed.toUint16(),
            baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed.toUint16()
        );

        emit IporRiskManagementOracleAssetAdded(asset);
    }

    function removeAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indicators[asset].lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        delete _indicators[asset];
        emit IporRiskManagementOracleAssetRemoved(asset);
    }

    function isAssetSupported(address asset) external view override returns (bool) {
        return _indicators[asset].lastUpdateTimestamp > 0;
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
        emit IporRiskManagementOracleUpdaterAdded(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        require(updater != address(0), IporErrors.WRONG_ADDRESS);

        _updaters[updater] = 0;
        emit IporRiskManagementOracleUpdaterRemoved(updater);
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
