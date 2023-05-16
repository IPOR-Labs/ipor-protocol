// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/types/IporTypes.sol";
import "./types/ItfDataProviderTypes.sol";
import "./ItfMilton.sol";
import "../amm/MiltonStorage.sol";
import "./ItfIporOracle.sol";
import "../interfaces/IMiltonSpreadInternal.sol";

contract ItfDataProvider is Initializable, UUPSUpgradeable, IporOwnableUpgradeable {
    // asset => milton addres for asset
    mapping(address => ItfMilton) private _miltons;
    mapping(address => MiltonStorage) private _miltonStorages;
    mapping(address => IMiltonSpreadInternal) private _miltonSpreadModels;
    ItfIporOracle private _iporOracle;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // all arrary contains adresses for 1) usdt, 2) usdc, 3) dai
    function initialize(
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address iporOracle,
        address[] memory miltonSpreadModels
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        uint256 i = 0;
        for (i; i < assets.length; i++) {
            _miltons[assets[i]] = ItfMilton(miltons[i]);
            _miltonStorages[assets[i]] = MiltonStorage(miltonStorages[i]);
            _miltonSpreadModels[assets[i]] = IMiltonSpreadInternal(miltonSpreadModels[i]);
        }
        _iporOracle = ItfIporOracle(iporOracle);
    }

    function getAmmData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfAmmData memory ammData)
    {
        ammData = ItfDataProviderTypes.ItfAmmData(
            block.number,
            timestamp,
            asset,
            getMiltonData(timestamp, asset),
            getIporOracleData(timestamp, asset),
            getMiltonStorageData(asset),
            getMiltonSpreadModelData(asset)
        );
    }

    function getMiltonData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfMiltonData memory miltonData)
    {
        ItfMilton milton = _miltons[asset];
        (int256 spreadPayFixed, int256 spreadReceiveFixed) = milton.itfCalculateSpread(timestamp);
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = milton.itfCalculateSoap(
            timestamp
        );

        (uint256 maxLeveragePayFixed, uint256 maxLeverageReceiveFixed) = milton.getMaxLeverage();
        (uint256 maxUtilizationRatePayFixed, uint256 maxUtilizationRateReceiveFixed) =
            milton.getMaxLpUtilizationPerLegRate();

        miltonData = ItfDataProviderTypes.ItfMiltonData(
            milton.getMaxSwapCollateralAmount(),
            milton.getMaxLpUtilizationRate(),
            maxUtilizationRatePayFixed,
            maxUtilizationRateReceiveFixed,
            milton.getOpeningFeeRate(),
            milton.getOpeningFeeTreasuryPortionRate(),
            milton.getIporPublicationFee(),
            milton.getLiquidationDepositAmount(),
            milton.getWadLiquidationDepositAmount(),
            maxLeveragePayFixed,
            maxLeverageReceiveFixed,
            milton.getMinLeverage(),
            spreadPayFixed,
            spreadReceiveFixed,
            soapPayFixed,
            soapReceiveFixed,
            soap
        );
    }

    function getIporOracleData(uint256 timestamp, address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfIporOracleData memory iporOracleData)
    {
        (
            uint256 indexValue,
            uint256 ibtPrice,
            uint256 lastUpdateTimestamp
        ) = _iporOracle.getIndex(asset);
        IporTypes.AccruedIpor memory accruedIndex = _iporOracle.getAccruedIndex(timestamp, asset);

        iporOracleData = ItfDataProviderTypes.ItfIporOracleData(
            indexValue,
            ibtPrice,
            lastUpdateTimestamp,
            accruedIndex.indexValue,
            accruedIndex.ibtPrice,
            accruedIndex.exponentialMovingAverage,
            accruedIndex.exponentialWeightedMovingVariance
        );
    }

    function getMiltonStorageData(address asset)
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

    function getMiltonSpreadModelData(address asset)
        public
        view
        returns (ItfDataProviderTypes.ItfMiltonSpreadModelData memory miltonSpreadModelData)
    {
        IMiltonSpreadInternal miltonSpreadModel = _miltonSpreadModels[asset];
        miltonSpreadModelData = ItfDataProviderTypes.ItfMiltonSpreadModelData(
            miltonSpreadModel.getPayFixedRegionOneBase(),
            miltonSpreadModel.getPayFixedRegionOneSlopeForVolatility(),
            miltonSpreadModel.getPayFixedRegionOneSlopeForMeanReversion(),
            miltonSpreadModel.getPayFixedRegionTwoBase(),
            miltonSpreadModel.getPayFixedRegionTwoSlopeForVolatility(),
            miltonSpreadModel.getPayFixedRegionTwoSlopeForMeanReversion(),
            miltonSpreadModel.getReceiveFixedRegionOneBase(),
            miltonSpreadModel.getReceiveFixedRegionOneSlopeForVolatility(),
            miltonSpreadModel.getReceiveFixedRegionOneSlopeForMeanReversion(),
            miltonSpreadModel.getReceiveFixedRegionTwoBase(),
            miltonSpreadModel.getReceiveFixedRegionTwoSlopeForVolatility(),
            miltonSpreadModel.getReceiveFixedRegionTwoSlopeForMeanReversion()
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
