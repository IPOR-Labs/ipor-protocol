// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IProxyImplementation.sol";
import "../libraries/errors/IporRiskManagementOracleErrors.sol";
import "../security/PauseManager.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./libraries/IporRiskManagementOracleStorageTypes.sol";
import "../interfaces/IIporContractCommonGov.sol";

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
    IIporRiskManagementOracle,
    IIporContractCommonGov,
    IProxyImplementation
{
    using SafeCast for uint256;
    using SafeCast for int256;

    mapping(address => uint256) internal _updaters;
    mapping(address => IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage) internal _indicators;

    /// @dev 0 - 31 bytes - lastUpdateTimestamp - uint32 - number of seconds since 1970-01-01T00:00:00Z
    /// @dev 32 - 55 bytes - baseSpread28dPayFixed - int24 - base spread for 28 days period for pay fixed leg,
    /// @dev    - on 32th position it is a sing - 1 means negative, 0 means positive
    /// @dev 56 - 79 bytes - baseSpread28dReceiveFixed - int24 - base spread for 28 days period for receive fixed leg,
    /// @dev    - on 56 position it is a sing - 1 means negative, 0 means positive
    /// @dev 80 - 103 bytes - baseSpread60dPayFixed - int24 - base spread for 60 days period for pay fixed leg,
    /// @dev    - on 80 position it is a sing - 1 means negative, 0 means positive
    /// @dev 104 - 127 bytes - baseSpread60dReceiveFixed - int24 - base spread for 60 days period for receive fixed leg,
    /// @dev    - on 104 position it is a sing - 1 means negative, 0 means positive
    /// @dev 128 - 151 bytes - baseSpread90dPayFixed - int24 - base spread for 90 days period for pay fixed leg,
    /// @dev   - on 128 position it is a sing - 1 means negative, 0 means positive
    /// @dev 152 - 175 bytes - baseSpread90dReceiveFixed - int24 - base spread for 90 days period for receive fixed leg,
    /// @dev    - on 152 position it is a sing - 1 means negative, 0 means positive
    /// @dev 176 - 187 bytes - fixedRateCap28dPayFixed - uint12 - fixed rate cap for 28 days period for pay fixed leg,
    /// @dev 188 - 199 bytes - fixedRateCap28dReceiveFixed - uint12 - fixed rate cap for 28 days period for receive fixed leg,
    /// @dev 200 - 211 bytes - fixedRateCap60dPayFixed - uint12 - fixed rate cap for 60 days period for pay fixed leg,
    /// @dev 212 - 223 bytes - fixedRateCap60dReceiveFixed - uint12 - fixed rate cap for 60 days period for receive fixed leg,
    /// @dev 224 - 235 bytes - fixedRateCap90dPayFixed - uint12 - fixed rate cap for 90 days period for pay fixed leg,
    mapping(address => bytes32) internal _baseSpreadsAndFixedRateCaps;

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyUpdater() {
        require(_updaters[msg.sender] == 1, IporRiskManagementOracleErrors.CALLER_NOT_UPDATER);
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

        for (uint256 i; i != assetsLength; ) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(
                riskIndicators[i].demandSpreadFactor28 != 0 &&
                    riskIndicators[i].demandSpreadFactor60 != 0 &&
                    riskIndicators[i].demandSpreadFactor90 != 0,
                IporErrors.VALUE_NOT_GREATER_THAN_ZERO
            );
            _indicators[assets[i]] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
                riskIndicators[i].maxNotionalPayFixed.toUint64(),
                riskIndicators[i].maxNotionalReceiveFixed.toUint64(),
                riskIndicators[i].maxCollateralRatioPayFixed.toUint16(),
                riskIndicators[i].maxCollateralRatioReceiveFixed.toUint16(),
                riskIndicators[i].maxCollateralRatio.toUint16(),
                block.timestamp.toUint32(),
                riskIndicators[i].demandSpreadFactor28.toUint16(),
                riskIndicators[i].demandSpreadFactor60.toUint16(),
                riskIndicators[i].demandSpreadFactor90.toUint16()
            );

            emit RiskIndicatorsUpdated(
                assets[i],
                riskIndicators[i].maxNotionalPayFixed,
                riskIndicators[i].maxNotionalReceiveFixed,
                riskIndicators[i].maxCollateralRatioPayFixed,
                riskIndicators[i].maxCollateralRatioReceiveFixed,
                riskIndicators[i].maxCollateralRatio,
                riskIndicators[i].demandSpreadFactor28,
                riskIndicators[i].demandSpreadFactor60,
                riskIndicators[i].demandSpreadFactor90
            );

            _baseSpreadsAndFixedRateCaps[assets[i]] = _baseSpreadsAndFixedRateCapsStorageToBytes32(
                IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
                    block.timestamp,
                    baseSpreadsAndFixedRateCaps[i].spread28dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].spread28dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].spread60dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].spread60dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].spread90dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].spread90dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap28dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap28dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap60dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap60dReceiveFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap90dPayFixed,
                    baseSpreadsAndFixedRateCaps[i].fixedRateCap90dReceiveFixed
                )
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
            unchecked {
                ++i;
            }
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
    }

    function getOpenSwapParameters(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    )
        external
        view
        override
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxCollateralRatioPerLeg,
            uint256 maxCollateralRatio,
            int256 baseSpreadPerLeg,
            uint256 fixedRateCapPerLeg,
            uint256 demandSpreadFactor
        )
    {
        (
            maxNotionalPerLeg,
            maxCollateralRatioPerLeg,
            maxCollateralRatio,
            demandSpreadFactor
        ) = _getRiskIndicatorsPerLeg(asset, direction, tenor);
        (baseSpreadPerLeg, fixedRateCapPerLeg) = _getSpread(asset, direction, tenor);
        /// @dev baseSpreadPerLeg is a value in percentage with 4 decimals (example: 1 = 0.0001%), so we need to multiply by 1e12 to achieve value in 18 decimals.
        /// @dev fixedRateCapPerLeg is a value in percentage with 2 decimals (example: 100 = 1%, 1 = 0.01%), so we need to multiply by 1e14 to achieve value in 18 decimals.
        return (
            maxNotionalPerLeg,
            maxCollateralRatioPerLeg,
            maxCollateralRatio,
            baseSpreadPerLeg * 1e12,
            fixedRateCapPerLeg * 1e14,
            demandSpreadFactor
        );
    }

    function getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor
    )
        external
        view
        override
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor
        )
    {
        return _getRiskIndicators(asset, tenor);
    }

    function getBaseSpreads(
        address asset
    )
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
            memory baseSpreadsAndFixedRateCaps = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );
        /// @dev Spread value is represented in percentage with 4 decimals (example: 1 = 0.0001%, more details check in structure description `IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage`),
        /// in return values are represented in 18 decimals, so we need to multiply by 1e12.
        return (
            uint256(baseSpreadsAndFixedRateCaps.lastUpdateTimestamp),
            int256(baseSpreadsAndFixedRateCaps.spread28dPayFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread28dReceiveFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread60dPayFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread60dReceiveFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread90dPayFixed) * 1e12,
            int256(baseSpreadsAndFixedRateCaps.spread90dReceiveFixed) * 1e12
        );
    }

    function getFixedRateCaps(
        address asset
    )
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

    function isAssetSupported(address asset) external view override returns (bool) {
        return _indicators[asset].lastUpdateTimestamp > 0;
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    function updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    ) external override onlyUpdater whenNotPaused {
        require(
            demandSpreadFactor28 != 0 &&
            demandSpreadFactor60 != 0 &&
            demandSpreadFactor90 != 0,
            IporErrors.VALUE_NOT_GREATER_THAN_ZERO
        );
        _updateRiskIndicators(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxCollateralRatioPayFixed,
            maxCollateralRatioReceiveFixed,
            maxCollateralRatio,
            demandSpreadFactor28,
            demandSpreadFactor60,
            demandSpreadFactor90
        );
    }

    function updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external override onlyUpdater whenNotPaused {
        _updateBaseSpreadsAndFixedRateCaps(asset, baseSpreadsAndFixedRateCaps);
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
            riskIndicators.maxCollateralRatioPayFixed.toUint16(),
            riskIndicators.maxCollateralRatioReceiveFixed.toUint16(),
            riskIndicators.maxCollateralRatio.toUint16(),
            block.timestamp.toUint32(),
            riskIndicators.demandSpreadFactor28.toUint16(),
            riskIndicators.demandSpreadFactor60.toUint16(),
            riskIndicators.demandSpreadFactor90.toUint16()
        );

        _baseSpreadsAndFixedRateCaps[asset] = _baseSpreadsAndFixedRateCapsStorageToBytes32(
            IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
                block.timestamp,
                baseSpreadsAndFixedRateCaps.spread28dPayFixed,
                baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread60dPayFixed,
                baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread90dPayFixed,
                baseSpreadsAndFixedRateCaps.spread90dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
            )
        );

        emit IporRiskManagementOracleAssetAdded(asset);
    }

    function removeAsset(address asset) external override onlyOwner {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(_indicators[asset].lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        delete _indicators[asset];
        emit IporRiskManagementOracleAssetRemoved(asset);
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

    function pause() external override onlyPauseGuardian {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external override onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _getRiskIndicators(
        address asset,
        IporTypes.SwapTenor tenor
    )
        internal
        view
        returns (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatio,
            uint256 lastUpdateTimestamp,
            uint256 demandSpreadFactor
        )
    {
        IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage memory indicators = _indicators[asset];
        require(indicators.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            demandSpreadFactor = uint256(indicators.demandSpreadFactor28);
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            demandSpreadFactor = uint256(indicators.demandSpreadFactor60);
        } else {
            demandSpreadFactor = uint256(indicators.demandSpreadFactor90);
        }

        /// @dev Multiplication by 1e22 or by 1e14 is needed to achieve WAD number used internally in calculations (value represented in 18 decimals)
        /// For more information check description for `IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage`
        return (
            uint256(indicators.maxNotionalPayFixed) * 1e22, /// @dev field represents number without decimals and with multiplication of 10_000,  1 = 10k
            uint256(indicators.maxNotionalReceiveFixed) * 1e22, /// @dev field represents number without decimals and with multiplication of 10_000,  1 = 10k
            uint256(indicators.maxCollateralRatioPayFixed) * 1e14, /// @dev Value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
            uint256(indicators.maxCollateralRatioReceiveFixed) * 1e14, /// @dev Value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
            uint256(indicators.maxCollateralRatio) * 1e14, /// @dev Value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
            uint256(indicators.lastUpdateTimestamp),
            demandSpreadFactor
        );
    }

    function _getRiskIndicatorsPerLeg(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    )
        internal
        view
        returns (
            uint256 maxNotionalPerLeg,
            uint256 maxCollateralRatioPerLeg,
            uint256 maxCollateralRatio,
            uint256 demandSpreadFactor
        )
    {
        (
            uint256 maxNotionalPayFixed,
            uint256 maxNotionalReceiveFixed,
            uint256 maxCollateralRatioPayFixed,
            uint256 maxCollateralRatioReceiveFixed,
            uint256 maxCollateralRatioBothLegs,
            ,
            uint256 demandSpreadFactorStorage
        ) = _getRiskIndicators(asset, tenor);

        if (direction == 0) {
            return (
                maxNotionalPayFixed,
                maxCollateralRatioPayFixed,
                maxCollateralRatioBothLegs,
                demandSpreadFactorStorage
            );
        } else {
            return (
                maxNotionalReceiveFixed,
                maxCollateralRatioReceiveFixed,
                maxCollateralRatioBothLegs,
                demandSpreadFactorStorage
            );
        }
    }

    /// @return int256 - base spread, value represents percentage with 4 decimals, example: 1 = 0.0001%
    /// @return uint256 - fixed rate cap, value represents percentage with 2 decimals, example: 100 = 1%
    function _getSpread(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor
    ) internal view returns (int256, uint256) {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCaps = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        if (tenor == IporTypes.SwapTenor.DAYS_28) {
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
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
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

    function _getFixedRateCaps(
        address asset
    )
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
            memory baseSpreadsAndFixedRateCaps = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );
        require(
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        /// @dev Cap values represent percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        /// To achieve WAD number used internally in calculations (value represented in 18 decimals) we need to multiply by 1e14
        return (
            baseSpreadsAndFixedRateCaps.lastUpdateTimestamp,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed * 1e14,
            baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed * 1e14
        );
    }

    function _updateRiskIndicators(
        address asset,
        uint256 maxNotionalPayFixed,
        uint256 maxNotionalReceiveFixed,
        uint256 maxCollateralRatioPayFixed,
        uint256 maxCollateralRatioReceiveFixed,
        uint256 maxCollateralRatio,
        uint256 demandSpreadFactor28,
        uint256 demandSpreadFactor60,
        uint256 demandSpreadFactor90
    ) internal {
        IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage memory indicators = _indicators[asset];

        require(indicators.lastUpdateTimestamp > 0, IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED);

        _indicators[asset] = IporRiskManagementOracleStorageTypes.RiskIndicatorsStorage(
            maxNotionalPayFixed.toUint64(),
            maxNotionalReceiveFixed.toUint64(),
            maxCollateralRatioPayFixed.toUint16(),
            maxCollateralRatioReceiveFixed.toUint16(),
            maxCollateralRatio.toUint16(),
            block.timestamp.toUint32(),
            demandSpreadFactor28.toUint16(),
            demandSpreadFactor60.toUint16(),
            demandSpreadFactor90.toUint16()
        );

        emit RiskIndicatorsUpdated(
            asset,
            maxNotionalPayFixed,
            maxNotionalReceiveFixed,
            maxCollateralRatioPayFixed,
            maxCollateralRatioReceiveFixed,
            maxCollateralRatio,
            demandSpreadFactor28,
            demandSpreadFactor60,
            demandSpreadFactor90
        );
    }

    function _updateBaseSpreadsAndFixedRateCaps(
        address asset,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) internal {
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage
            memory baseSpreadsAndFixedRateCapsStorage = _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
                _baseSpreadsAndFixedRateCaps[asset]
            );

        require(
            baseSpreadsAndFixedRateCapsStorage.lastUpdateTimestamp > 0,
            IporRiskManagementOracleErrors.ASSET_NOT_SUPPORTED
        );

        _baseSpreadsAndFixedRateCaps[asset] = _baseSpreadsAndFixedRateCapsStorageToBytes32(
            IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage(
                block.timestamp,
                baseSpreadsAndFixedRateCaps.spread28dPayFixed,
                baseSpreadsAndFixedRateCaps.spread28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread60dPayFixed,
                baseSpreadsAndFixedRateCaps.spread60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.spread90dPayFixed,
                baseSpreadsAndFixedRateCaps.spread90dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap28dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap60dReceiveFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dPayFixed,
                baseSpreadsAndFixedRateCaps.fixedRateCap90dReceiveFixed
            )
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

    function _baseSpreadsAndFixedRateCapsStorageToBytes32(
        IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage memory toSave
    ) internal pure returns (bytes32 result) {
        require(toSave.lastUpdateTimestamp < type(uint32).max, "lastUpdateTimestamp overflow");
        require(
            -type(int24).max < toSave.spread28dPayFixed && toSave.spread28dPayFixed < type(int24).max,
            "spread28dPayFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread28dReceiveFixed && toSave.spread28dReceiveFixed < type(int24).max,
            "spread28dReceiveFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread60dPayFixed && toSave.spread60dPayFixed < type(int24).max,
            "spread60dPayFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread60dReceiveFixed && toSave.spread60dReceiveFixed < type(int24).max,
            "spread60dReceiveFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread90dPayFixed && toSave.spread90dPayFixed < type(int24).max,
            "spread90dPayFixed overflow"
        );
        require(
            -type(int24).max < toSave.spread90dReceiveFixed && toSave.spread90dReceiveFixed < type(int24).max,
            "spread90dReceiveFixed overflow"
        );
        require(toSave.fixedRateCap28dPayFixed < 2 ** 12, "fixedRateCap28dPayFixed overflow");
        require(toSave.fixedRateCap28dReceiveFixed < 2 ** 12, "fixedRateCap28dReceiveFixed overflow");
        require(toSave.fixedRateCap60dPayFixed < 2 ** 12, "fixedRateCap60dPayFixed overflow");
        require(toSave.fixedRateCap60dReceiveFixed < 2 ** 12, "fixedRateCap60dReceiveFixed overflow");
        require(toSave.fixedRateCap90dPayFixed < 2 ** 12, "fixedRateCap90dPayFixed overflow");
        require(toSave.fixedRateCap90dReceiveFixed < 2 ** 12, "fixedRateCap90dReceiveFixed overflow");

        assembly {
            function abs(value) -> y {
                switch slt(value, 0)
                case true {
                    y := sub(0, value)
                }
                case false {
                    y := value
                }
            }

            result := add(
                mload(toSave),
                add(
                    shl(32, slt(mload(add(toSave, 32)), 0)),
                    add(
                        shl(33, abs(mload(add(toSave, 32)))),
                        add(
                            shl(56, slt(mload(add(toSave, 64)), 0)),
                            add(
                                shl(57, abs(mload(add(toSave, 64)))),
                                add(
                                    shl(80, slt(mload(add(toSave, 96)), 0)), //spread60dPayFixed
                                    add(
                                        shl(81, abs(mload(add(toSave, 96)))), //spread60dPayFixed
                                        add(
                                            shl(104, slt(mload(add(toSave, 128)), 0)), //spread60dReceiveFixed
                                            add(
                                                shl(105, abs(mload(add(toSave, 128)))), //spread60dReceiveFixed
                                                add(
                                                    shl(128, slt(mload(add(toSave, 160)), 0)), //spread90dPayFixed
                                                    add(
                                                        shl(129, abs(mload(add(toSave, 160)))), //spread90dPayFixed
                                                        add(
                                                            shl(152, slt(mload(add(toSave, 192)), 0)), //spread90dReceiveFixed
                                                            add(
                                                                shl(153, abs(mload(add(toSave, 192)))), //spread90dReceiveFixed
                                                                add(
                                                                    shl(176, mload(add(toSave, 224))), //fixedRateCap28dPayFixed
                                                                    add(
                                                                        shl(188, mload(add(toSave, 256))), //fixedRateCap28dReceiveFixed
                                                                        add(
                                                                            shl(200, mload(add(toSave, 288))), //fixedRateCap60dPayFixed
                                                                            add(
                                                                                shl(212, mload(add(toSave, 320))), //fixedRateCap60dReceiveFixed
                                                                                add(
                                                                                    shl(224, mload(add(toSave, 352))), //fixedRateCap90dPayFixed
                                                                                    shl(236, mload(add(toSave, 384))) //fixedRateCap90dReceiveFixed
                                                                                )
                                                                            )
                                                                        )
                                                                    )
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        }
        return result;
    }

    function _bytes32ToBaseSpreadsAndFixedRateCapsStorage(
        bytes32 toSave
    ) internal pure returns (IporRiskManagementOracleStorageTypes.BaseSpreadsAndFixedRateCapsStorage memory result) {
        assembly {
            function convertToInt(sign, value) -> y {
                switch sign
                case 0 {
                    y := value
                }
                case 1 {
                    y := sub(0, value)
                }
            }
            mstore(result, and(toSave, 0xFFFFFFFF)) // lastUpdateTimestamp
            mstore(add(result, 32), convertToInt(and(shr(32, toSave), 0x1), and(shr(33, toSave), 0x7FFFFF))) // spread28dPayFixed
            mstore(add(result, 64), convertToInt(and(shr(56, toSave), 0x1), and(shr(57, toSave), 0x7FFFFF))) // spread28dReceiveFixed
            mstore(add(result, 96), convertToInt(and(shr(80, toSave), 0x1), and(shr(81, toSave), 0x7FFFFF))) // spread60dPayFixed
            mstore(add(result, 128), convertToInt(and(shr(104, toSave), 0x1), and(shr(105, toSave), 0x7FFFFF))) // spread60dReceiveFixed
            mstore(add(result, 160), convertToInt(and(shr(128, toSave), 0x1), and(shr(129, toSave), 0x7FFFFF))) // spread90dPayFixed
            mstore(add(result, 192), convertToInt(and(shr(152, toSave), 0x1), and(shr(153, toSave), 0x7FFFFF))) // spread90dReceiveFixed
            mstore(add(result, 224), and(shr(176, toSave), 0xFFF)) // fixedRateCap28dPayFixed
            mstore(add(result, 256), and(shr(188, toSave), 0xFFF)) // fixedRateCap28dReceiveFixed
            mstore(add(result, 288), and(shr(200, toSave), 0xFFF)) // fixedRateCap60dPayFixed
            mstore(add(result, 320), and(shr(212, toSave), 0xFFF)) // fixedRateCap60dReceiveFixed
            mstore(add(result, 352), and(shr(224, toSave), 0xFFF)) // fixedRateCap90dPayFixed
            mstore(add(result, 384), and(shr(236, toSave), 0xFFF)) // fixedRateCap90dReceiveFixed
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
