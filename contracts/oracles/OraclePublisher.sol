// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/IporOracleErrors.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IOraclePublisher.sol";
import "../security/IporOwnableUpgradeable.sol";

/**
 * @title IPOR Oracle Publisher contract
 *
 * @author IPOR Labs
 */
contract OraclePublisher is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IOraclePublisher
{
    IIporOracle internal immutable _iporOracle;
    IIporRiskManagementOracle internal immutable _iporRiskManagementOracle;

    mapping(address => uint256) internal _updaters;

    modifier onlyUpdater() {
        require(_updaters[_msgSender()] == 1, IporOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIporOracle iporOracle, IIporRiskManagementOracle iporRiskManagementOracle) {
        _disableInitializers();

        _iporOracle = iporOracle;
        _iporRiskManagementOracle = iporRiskManagementOracle;
    }

    function initialize() public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
    }

    function getConfiguration() external view returns (address iporOracle, address iporRiskManagementOracle) {
        return (address(_iporOracle), address(_iporRiskManagementOracle));
    }

    function publish(
        address asset,
        uint256 indexValue,
        IporRiskManagementOracleTypes.RiskIndicators calldata riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps calldata baseSpreadsAndFixedRateCaps
    ) external override onlyUpdater whenNotPaused {
        address[] memory assets = new address[](1);
        assets[0] = asset;

        uint256[] memory indexValues = new uint256[](1);
        indexValues[0] = indexValue;

        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicatorsArray = new IporRiskManagementOracleTypes.RiskIndicators[](1);
        riskIndicatorsArray[0] = riskIndicators;

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsAndFixedRateCapsArray = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](
                1
            );
        baseSpreadsAndFixedRateCapsArray[0] = baseSpreadsAndFixedRateCaps;

        _updateOracles(assets, indexValues, riskIndicatorsArray, baseSpreadsAndFixedRateCapsArray, block.timestamp);
    }

    function addUpdater(address updater) external override onlyOwner whenNotPaused {
        _updaters[updater] = 1;
        emit IporOracleUpdateFacadeAddUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner whenNotPaused {
        _updaters[updater] = 0;
        emit IporOracleUpdateFacadeRemoveUpdater(updater);
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _updateOracles(
        address[] memory assets,
        uint256[] memory indexValues,
        IporRiskManagementOracleTypes.RiskIndicators[] memory riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[] memory baseSpreadsAndFixedRateCaps,
        uint256 updateTimestamp
    ) internal {
        uint256 assetsLength = assets.length;
        require(
            assetsLength == indexValues.length &&
                assetsLength == riskIndicators.length &&
                assetsLength == baseSpreadsAndFixedRateCaps.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        for (uint256 i; i != assets.length; ++i) {
            _iporOracle.updateIndex(assets[i], indexValues[i]);
            _iporRiskManagementOracle.updateRiskIndicators(
                assets[i],
                riskIndicators[i].maxNotionalPayFixed,
                riskIndicators[i].maxNotionalReceiveFixed,
                riskIndicators[i].maxUtilizationRatePayFixed,
                riskIndicators[i].maxUtilizationRateReceiveFixed,
                riskIndicators[i].maxUtilizationRate
            );
            _iporRiskManagementOracle.updateBaseSpreadsAndFixedRateCaps(assets[i], baseSpreadsAndFixedRateCaps[i]);
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
