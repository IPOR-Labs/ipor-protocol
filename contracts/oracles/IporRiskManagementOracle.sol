// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/RiskManagementOracleStorageTypes.sol";
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

    mapping(address => uint256) internal _updaters;
    mapping(address => IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage) internal _indicators;

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
        uint256[] memory maxNotionalPayFixed,
        uint256[] memory maxNotionalReceiveFixed,
        uint256[] memory maxUtilizationRatePayFixed,
        uint256[] memory maxUtilizationRateReceiveFixed,
        uint256[] memory maxUtilizationRate
    ) public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        require(
            assetsLength == maxNotionalPayFixed.length &&
                assetsLength == maxNotionalReceiveFixed.length &&
                assetsLength == maxUtilizationRatePayFixed.length &&
                assetsLength == maxUtilizationRateReceiveFixed.length &&
                assetsLength == maxUtilizationRate.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        for (uint256 i; i != assetsLength; ++i) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);

            _indicators[assets[i]] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
                maxNotionalPayFixed[i].toUint64(),
                maxNotionalReceiveFixed[i].toUint64(),
                maxUtilizationRatePayFixed[i].toUint16(),
                maxUtilizationRateReceiveFixed[i].toUint16(),
                maxUtilizationRate[i].toUint16(),
                block.timestamp.toUint32()
            );

            emit RiskIndicatorsUpdated(
                assets[i],
                maxNotionalPayFixed[i],
                maxNotionalReceiveFixed[i],
                maxUtilizationRatePayFixed[i],
                maxUtilizationRateReceiveFixed[i],
                maxUtilizationRate[i]
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

    function addAsset(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxUtilizationRatePayFixed,
        uint256 maxUtilizationRateReceiveFixed,
        uint256 maxUtilizationRate
    ) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _indicators[asset].lastUpdateTimestamp == 0,
            IporRiskManagementOracleErrors.CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS
        );

        _indicators[asset] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
            maxNotionalPayFixed.toUint64(),
            maxNotionalReceiveFixed.toUint64(),
            maxUtilizationRatePayFixed.toUint16(),
            maxUtilizationRateReceiveFixed.toUint16(),
            maxUtilizationRate.toUint16(),
            block.timestamp.toUint32()
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
