pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/types/IporTypes.sol";
import "./types/ItfDataProviderTypes.sol";
import "./ItfMilton.sol";
import "../amm/MiltonStorage.sol";
import "./ItfIporOracle.sol";
import "../amm/spread/MiltonSpreadModel.sol";

contract ItfDataProvider is UUPSUpgradeable, IporOwnableUpgradeable {
    // asset => milton addres for asset
    mapping(address => ItfMilton) _miltons;
    mapping(address => MiltonStorage) _miltonStorages;
    ItfIporOracle _iporOracle;
    MiltonSpreadModel _miltonSpreadModel;

    // all arrary contains adresses for 1) usdt, 2) usdc, 3) dai
    function initialize(
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address iporOracle,
        address miltonSpreadModel
    ) public initializer {
        uint256 i = 0;
        for (i; i < assets.length; i++) {
            _miltons[assets[i]] = ItfMilton(miltons[i]);
            _miltonStorages[assets[i]] = MiltonStorage(miltonStorages[i]);
        }
        _iporOracle = ItfIporOracle(iporOracle);
        _miltonSpreadModel = MiltonSpreadModel(miltonSpreadModel);
    }

    function itfAmmData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfAmmData memory ammData)
    {
        ammData = ItfDataProviderTypes.ItfAmmData(
            collectMiltonData(timestamp, asset),
            collectIporOracleData(timestamp, asset),
            collectMiltonStorageData(asset),
            collectMiltonSpreadModelData()
        );
    }

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/

    function collectMiltonData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfMiltonData memory miltonData)
    {
        ItfMilton milton = _miltons[asset];
        (int256 spreadPayFixed, int256 spreadReceiveFixed) = milton.itfCalculateSpread(timestamp);
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = milton.itfCalculateSoap(
            timestamp
        );

        miltonData = ItfDataProviderTypes.ItfMiltonData(
            milton.getMaxSwapCollateralAmount(),
            milton.getMaxLpUtilizationRate(),
            milton.getMaxLpUtilizationPerLegRate(),
            milton.getIncomeFeeRate(),
            milton.getOpeningFeeRate(),
            milton.getOpeningFeeTreasuryPortionRate(),
            milton.getIporPublicationFee(),
            milton.getLiquidationDepositAmount(),
            milton.getWadLiquidationDepositAmount(),
            milton.getMaxLeverage(),
            milton.getMinLeverage(),
            spreadPayFixed,
            spreadReceiveFixed,
            soapPayFixed,
            soapReceiveFixed,
            soap
        );
    }

    function collectIporOracleData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfIporOracleData memory iporOracleData)
    {
        (
            uint256 indexValue,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 lastUpdateTimestamp
        ) = _iporOracle.getIndex(asset);
        IporTypes.AccruedIpor memory accruedIndex = _iporOracle.getAccruedIndex(timestamp, asset);

        iporOracleData = ItfDataProviderTypes.ItfIporOracleData(
            _iporOracle.itfGetDecayFactorValue(timestamp),
            indexValue,
            ibtPrice,
            exponentialMovingAverage,
            exponentialWeightedMovingVariance,
            lastUpdateTimestamp,
            accruedIndex.indexValue,
            accruedIndex.ibtPrice,
            accruedIndex.exponentialMovingAverage,
            accruedIndex.exponentialWeightedMovingVariance
        );
    }

    function collectMiltonStorageData(address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfMiltonStorageData memory miltonStorageData)
    {
        MiltonStorage miltonStorage = _miltonStorages[asset];
        MiltonStorageTypes.ExtendedBalancesMemory memory balance = miltonStorage
            .getExtendedBalance();
        (uint256 totalNotionalPayFixed, uint256 totalNotionalReceiveFixed) = miltonStorage
            .getTotalOutstandingNotional();
        miltonStorageData = ItfDataProviderTypes.ItfMiltonStorageData(
            balance.totalCollateralPayFixed,
            balance.totalCollateralReceiveFixed,
            balance.liquidityPool,
            balance.vault,
            balance.iporPublicationFee,
            balance.treasury,
            totalNotionalPayFixed,
            totalNotionalReceiveFixed
        );
    }

    function collectMiltonSpreadModelData()
        public
        view
        returns (ItfDataProviderTypes.ItfMiltonSpreadModelData memory miltonSpreadModelData)
    {
        miltonSpreadModelData = ItfDataProviderTypes.ItfMiltonSpreadModelData(
            _miltonSpreadModel.getSpreadPremiumsMaxValue(),
            _miltonSpreadModel.getDCKfValue(),
            _miltonSpreadModel.getDCLambdaValue(),
            _miltonSpreadModel.getDCKOmegaValue(),
            _miltonSpreadModel.getDCMaxLiquidityRedemptionValue(),
            _miltonSpreadModel.getPayFixedRegionOneBase(),
            _miltonSpreadModel.getPayFixedRegionOneSlopeForVolatility(),
            _miltonSpreadModel.getPayFixedRegionOneSlopeForMeanReversion(),
            _miltonSpreadModel.getPayFixedRegionTwoBase(),
            _miltonSpreadModel.getPayFixedRegionTwoSlopeForVolatility(),
            _miltonSpreadModel.getPayFixedRegionTwoSlopeForMeanReversion(),
            _miltonSpreadModel.getReceiveFixedRegionOneBase(),
            _miltonSpreadModel.getReceiveFixedRegionOneSlopeForVolatility(),
            _miltonSpreadModel.getReceiveFixedRegionOneSlopeForMeanReversion(),
            _miltonSpreadModel.getReceiveFixedRegionTwoBase(),
            _miltonSpreadModel.getReceiveFixedRegionTwoSlopeForVolatility(),
            _miltonSpreadModel.getReceiveFixedRegionTwoSlopeForMeanReversion()
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
