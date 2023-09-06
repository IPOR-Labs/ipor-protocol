// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../../amm/spread/ISpread60Days.sol";
import "../../amm/spread/ISpread60DaysLens.sol";
import "../../libraries/errors/IporOracleErrors.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/IporContractValidator.sol";
import "../../amm/spread/DemandSpreadLibs.sol";
import "../../amm/spread/SpreadStorageLibs.sol";
import "../../amm/spread/OfferedRateCalculationLibs.sol";

contract Spread60Days is ISpread60Days, ISpread60DaysLens {
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    address internal immutable _dai;
    address internal immutable _usdc;
    address internal immutable _usdt;

    constructor(address dai, address usdc, address usdt) {
        _dai = dai.checkAddress();
        _usdc = usdc.checkAddress();
        _usdt = usdt.checkAddress();
    }

    function calculateAndUpdateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixedAndUpdateTimeWeightedNotional60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixed60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateAndUpdateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixedAndUpdateTimeWeightedNotional60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixed60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _dai;
        assets[1] = _usdc;
        assets[2] = _usdt;
        return assets;
    }

    function spreadFunction60DaysConfig() external pure returns (uint256[] memory) {
        return DemandSpreadLibs.spreadFunctionConfig();
    }

    function _calculateDemandPayFixed60Day(
        IporTypes.SpreadInputs memory spreadInputs
    ) internal view returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);
        spreadValue = DemandSpreadLibs.calculatePayFixedSpread(inputData);
    }

    function _calculateDemandPayFixedAndUpdateTimeWeightedNotional60Day(
        IporTypes.SpreadInputs memory spreadInputs
    ) internal returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculatePayFixedSpread(inputData);

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
            inputData.timeWeightedNotionalStorageId
        );

        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalPayFixed(
            weightedNotional,
            inputData.swapNotional,
            60 days
        );
    }

    function _calculateDemandReceiveFixed60Day(
        IporTypes.SpreadInputs calldata spreadInputs
    ) internal view returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculateReceiveFixedSpread(inputData);
    }

    function _calculateDemandReceiveFixedAndUpdateTimeWeightedNotional60Day(
        IporTypes.SpreadInputs calldata spreadInputs
    ) internal returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculateReceiveFixedSpread(inputData);

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
            inputData.timeWeightedNotionalStorageId
        );

        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalReceiveFixed(
            weightedNotional,
            inputData.swapNotional,
            60 days
        );
    }

    function _getSpreadConfigForDemand(
        IporTypes.SpreadInputs memory spreadInputs
    ) internal view returns (DemandSpreadLibs.SpreadInputData memory inputData) {
        inputData = DemandSpreadLibs.SpreadInputData({
            totalCollateralPayFixed: spreadInputs.totalCollateralPayFixed,
            totalCollateralReceiveFixed: spreadInputs.totalCollateralReceiveFixed,
            liquidityPoolBalance: spreadInputs.liquidityPoolBalance,
            totalNotionalPayFixed: spreadInputs.totalNotionalPayFixed,
            totalNotionalReceiveFixed: spreadInputs.totalNotionalReceiveFixed,
            swapNotional: spreadInputs.swapNotional,
            maxLeveragePerLeg: spreadInputs.maxLeveragePerLeg,
            maxLpCollateralRatioPerLegRate: spreadInputs.maxLpCollateralRatioPerLegRate,
            tenorsInSeconds: new uint256[](3),
            timeWeightedNotionalStorageIds: new SpreadStorageLibs.StorageId[](3),
            timeWeightedNotionalStorageId: SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai
        });

        inputData.tenorsInSeconds[0] = 28 days;
        inputData.tenorsInSeconds[1] = 60 days;
        inputData.tenorsInSeconds[2] = 90 days;

        if (spreadInputs.asset == _usdc) {
            inputData.timeWeightedNotionalStorageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc;
            inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc;
            return inputData;
        } else if (spreadInputs.asset == _usdt) {
            inputData.timeWeightedNotionalStorageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt;
            inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt;
            return inputData;
        } else if (spreadInputs.asset == _dai) {
            inputData.timeWeightedNotionalStorageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
            inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;
            return inputData;
        }
        revert(string.concat(IporOracleErrors.ASSET_NOT_SUPPORTED, " ", Strings.toHexString(spreadInputs.asset)));
    }
}
