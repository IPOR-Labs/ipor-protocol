// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/libraries/errors/IporOracleErrors.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "./ISpread60Days.sol";
import "./ISpread60DaysLens.sol";
import "./DemandSpreadLibs.sol";
import "./SpreadStorageLibs.sol";
import "./OfferedRateCalculationLibs.sol";


contract Spread60Days is ISpread60Days, ISpread60DaysLens {
    using SafeCast for uint256;
    using SafeCast for int256;

    address internal immutable _DAI;
    address internal immutable _USDC;
    address internal immutable _USDT;

    constructor(
        address dai,
        address usdc,
        address usdt
    ) {
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI"));
        require(usdc != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC"));
        require(usdt != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT"));
        _DAI = dai;
        _USDC = usdc;
        _USDT = usdt;
    }

    function calculateAndUpdateOfferedRatePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 offeredRate)
    {
        offeredRate = OfferedRateCalculationLibs.calculatePayFixedOfferedRate(
            spreadInputs.indexValue,
            spreadInputs.baseSpread,
            _calculateDemandPayFixedAndUpdateTimeWeightedNotional60Day(spreadInputs),
            spreadInputs.cap
        );
    }

    function calculateOfferedRatePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 offeredRate)
    {
        offeredRate = OfferedRateCalculationLibs.calculatePayFixedOfferedRate(
            spreadInputs.indexValue,
            spreadInputs.baseSpread,
            _calculateDemandPayFixed60Day(spreadInputs),
            spreadInputs.cap
        );
    }

    function calculateQuoteReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 offeredRate)
    {
        offeredRate = OfferedRateCalculationLibs.calculateReceiveFixedOfferedRate(
            spreadInputs.indexValue,
            spreadInputs.baseSpread,
            _calculateDemandReceiveFixedAndUpdateTimeWeightedNotional60Day(spreadInputs),
            spreadInputs.cap
        );
    }


    function calculateReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 offeredRate)
    {
        offeredRate = OfferedRateCalculationLibs.calculateReceiveFixedOfferedRate(
            spreadInputs.indexValue,
            spreadInputs.baseSpread,
            _calculateDemandReceiveFixed60Day(spreadInputs),
            spreadInputs.cap
        );
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _DAI;
        assets[1] = _USDC;
        assets[2] = _USDT;
        return assets;
    }

    function spreadFunction60DaysConfig() external pure returns (uint256[] memory) {
        return DemandSpreadLibs.spreadFunctionConfig();
    }

    function _calculateDemandPayFixed60Day(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);
        spreadValue = DemandSpreadLibs.calculatePayFixedSpread(inputData);
    }

    function _calculateDemandPayFixedAndUpdateTimeWeightedNotional60Day(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculatePayFixedSpread(inputData);

            SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
                inputData.storageId
            );

            CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalPayFixed(
                weightedNotional,
                inputData.swapNotional,
                60 days
            );

    }

    function _calculateDemandReceiveFixed60Day(
        IporTypes.SpreadInputs calldata spreadInputs) internal returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculateReceiveFixedSpread(inputData);
    }
    function _calculateDemandReceiveFixedAndUpdateTimeWeightedNotional60Day(
        IporTypes.SpreadInputs calldata spreadInputs) internal returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculateReceiveFixedSpread(inputData);

            SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
                inputData.storageId
            );

            CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalReceiveFixed(
                weightedNotional,
                inputData.swapNotional,
                60 days
            );
    }

    function _getSpreadConfigForDemand(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (DemandSpreadLibs.SpreadInputData memory inputData)
    {
        inputData = DemandSpreadLibs.SpreadInputData({
            totalCollateralPayFixed: spreadInputs.totalCollateralPayFixed,
            totalCollateralReceiveFixed: spreadInputs.totalCollateralReceiveFixed,
            liquidityPool: spreadInputs.liquidityPool,
            totalNotionalPayFixed: spreadInputs.totalNotionalPayFixed,
            totalNotionalReceiveFixed: spreadInputs.totalNotionalReceiveFixed,
            swapNotional: spreadInputs.swapNotional,
            maxLeverage: spreadInputs.maxLeverage,
            maxLpUtilizationPerLegRate: spreadInputs.maxLpUtilizationPerLegRate,
            storageIds: new SpreadStorageLibs.StorageId[](3),
            maturities: new uint256[](3),
            storageId: SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai
        });

        inputData.maturities[0] = 28 days;
        inputData.maturities[1] = 60 days;
        inputData.maturities[2] = 90 days;

        if (spreadInputs.asset == _USDC) {
            inputData.storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            inputData.storageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc;
            return inputData;
        } else if (spreadInputs.asset == _USDT) {
            inputData.storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            inputData.storageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt;
            return inputData;
        } else if (spreadInputs.asset == _DAI) {
            inputData.storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            inputData.storageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
            inputData.storageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            inputData.storageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;
            return inputData;
        }
        revert(string.concat(IporOracleErrors.ASSET_NOT_SUPPORTED , " ", Strings.toHexString(spreadInputs.asset)));
    }
}
