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
    mapping(address => IporRiskManagementOracleStorageTypes.BaseSpreadsStorage) internal _baseSpreads;

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
        IporRiskManagementOracleTypes.BaseSpreads[] calldata baseSpreads
    ) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        require(
            assetsLength == riskIndicators.length && assetsLength == baseSpreads.length,
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

            _baseSpreads[assets[i]] = IporRiskManagementOracleStorageTypes.BaseSpreadsStorage(
                block.timestamp.toUint32(),
                baseSpreads[i].spread28dPayFixed.toInt24(),
                baseSpreads[i].spread28dReceiveFixed.toInt24(),
                baseSpreads[i].spread60dPayFixed.toInt24(),
                baseSpreads[i].spread60dReceiveFixed.toInt24(),
                baseSpreads[i].spread90dPayFixed.toInt24(),
                baseSpreads[i].spread90dReceiveFixed.toInt24()
            );

            emit BaseSpreadsUpdated(
                assets[i],
                baseSpreads[i].spread28dPayFixed,
                baseSpreads[i].spread28dReceiveFixed,
                baseSpreads[i].spread60dPayFixed,
                baseSpreads[i].spread60dReceiveFixed,
                baseSpreads[i].spread90dPayFixed,
                baseSpreads[i].spread90dReceiveFixed
            );
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
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
        IporRiskManagementOracleStorageTypes.BaseSpreadsStorage memory baseSpreads = _baseSpreads[asset];
        require(baseSpreads.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);
        return (
            uint256(baseSpreads.lastUpdateTimestamp),
            int256(baseSpreads.spread28dPayFixed),
            int256(baseSpreads.spread28dReceiveFixed),
            int256(baseSpreads.spread60dPayFixed),
            int256(baseSpreads.spread60dReceiveFixed),
            int256(baseSpreads.spread90dPayFixed),
            int256(baseSpreads.spread90dReceiveFixed)
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

    function updateBaseSpreads(
        address asset,
        int256 spread28dPayFixed,
        int256 spread28dReceiveFixed,
        int256 spread60dPayFixed,
        int256 spread60dReceiveFixed,
        int256 spread90dPayFixed,
        int256 spread90dReceiveFixed
    ) external override onlyUpdater whenNotPaused {
        _updateBaseSpreads(
            asset,
            spread28dPayFixed,
            spread28dReceiveFixed,
            spread60dPayFixed,
            spread60dReceiveFixed,
            spread90dPayFixed,
            spread90dReceiveFixed
        );
    }

    function updateBaseSpreads(
        address[] memory asset,
        int256[] memory spread28dPayFixed,
        int256[] memory spread28dReceiveFixed,
        int256[] memory spread60dPayFixed,
        int256[] memory spread60dReceiveFixed,
        int256[] memory spread90dPayFixed,
        int256[] memory spread90dReceiveFixed
    ) external override onlyUpdater whenNotPaused {
        uint256 assetsLength = asset.length;

        require(
            assetsLength == spread28dPayFixed.length &&
                assetsLength == spread28dReceiveFixed.length &&
                assetsLength == spread60dPayFixed.length &&
                assetsLength == spread60dReceiveFixed.length &&
                assetsLength == spread90dPayFixed.length &&
                assetsLength == spread90dReceiveFixed.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        for (uint256 i; i != assetsLength; ++i) {
            _updateBaseSpreads(
                asset[i],
                spread28dPayFixed[i],
                spread28dReceiveFixed[i],
                spread60dPayFixed[i],
                spread60dReceiveFixed[i],
                spread90dPayFixed[i],
                spread90dReceiveFixed[i]
            );
        }
    }

    function _updateBaseSpreads(
        address asset,
        int256 spread28dPayFixed,
        int256 spread28dReceiveFixed,
        int256 spread60dPayFixed,
        int256 spread60dReceiveFixed,
        int256 spread90dPayFixed,
        int256 spread90dReceiveFixed
    ) internal {
        IporRiskManagementOracleStorageTypes.BaseSpreadsStorage memory baseSpreads = _baseSpreads[asset];

        require(baseSpreads.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        _baseSpreads[asset] = IporRiskManagementOracleStorageTypes.BaseSpreadsStorage(
            block.timestamp.toUint32(),
            spread28dPayFixed.toInt24(),
            spread28dReceiveFixed.toInt24(),
            spread60dPayFixed.toInt24(),
            spread60dReceiveFixed.toInt24(),
            spread90dPayFixed.toInt24(),
            spread90dReceiveFixed.toInt24()
        );

        emit BaseSpreadsUpdated(
            asset,
            spread28dPayFixed,
            spread28dReceiveFixed,
            spread60dPayFixed,
            spread60dReceiveFixed,
            spread90dPayFixed,
            spread90dReceiveFixed
        );
    }

    function addAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreads calldata baseSpreads
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

        _baseSpreads[asset] = IporRiskManagementOracleStorageTypes.BaseSpreadsStorage(
            block.timestamp.toUint32(),
            baseSpreads.spread28dPayFixed.toInt24(),
            baseSpreads.spread28dReceiveFixed.toInt24(),
            baseSpreads.spread60dPayFixed.toInt24(),
            baseSpreads.spread60dReceiveFixed.toInt24(),
            baseSpreads.spread90dPayFixed.toInt24(),
            baseSpreads.spread90dReceiveFixed.toInt24()
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
