// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/libraries/errors/IporOracleErrors.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "./ISpread60Days.sol";
import "./ISpread60DaysLens.sol";
import "./ImbalanceSpreadLibs.sol";
import "./SpreadStorageLibs.sol";

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

    function calculateQuotePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalancePayFixedAndUpdateTimeWeightedNotional60Day(spreadInputs);

        int256 intQuoteValue = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread +
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValue > 0 ? intQuoteValue.toUint256() : 0;
    }

    function calculatePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalancePayFixed60Day(spreadInputs);

        int256 intQuoteValue = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread +
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValue > 0 ? intQuoteValue.toUint256() : 0;
    }

    function calculateQuoteReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional60Day(spreadInputs);

        int256 intQuoteValueWithIpor = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0;
    }


    function calculateReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        override
        returns (uint256 quoteValue)
    {
        uint256 imbalanceSpread = _calculateImbalanceReceiveFixed60Day(spreadInputs);

        int256 intQuoteValueWithIpor = spreadInputs.indexValue.toInt256() +
            spreadInputs.baseSpread -
            imbalanceSpread.toInt256();

        quoteValue = intQuoteValueWithIpor > 0 ? intQuoteValueWithIpor.toUint256() : 0;
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _DAI;
        assets[1] = _USDC;
        assets[2] = _USDT;
        return assets;
    }

    function spreadFunction60DaysConfig() external pure returns (uint256[] memory) {
        return ImbalanceSpreadLibs.spreadFunctionConfig();
    }

    function _calculateImbalancePayFixed60Day(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForImbalance(spreadInputs);
        spreadValue = ImbalanceSpreadLibs.calculatePayFixedSpread(inputData);
    }

    function _calculateImbalancePayFixedAndUpdateTimeWeightedNotional60Day(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (uint256 spreadValue)
    {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForImbalance(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculatePayFixedSpread(inputData);

            SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getWeightedNotional(
                inputData.storageId
            );

            CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalPayFixed(
                weightedNotional,
                inputData.swapNotional,
                60 days
            );

    }

    function _calculateImbalanceReceiveFixed60Day(
        IporTypes.SpreadInputs calldata spreadInputs) internal returns (uint256 spreadValue) {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForImbalance(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculateReceiveFixedSpread(inputData);
    }
    function _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional60Day(
        IporTypes.SpreadInputs calldata spreadInputs) internal returns (uint256 spreadValue) {
        ImbalanceSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForImbalance(spreadInputs);

        spreadValue = ImbalanceSpreadLibs.calculateReceiveFixedSpread(inputData);

            SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs.getWeightedNotional(
                inputData.storageId
            );

            CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalReceiveFixed(
                weightedNotional,
                inputData.swapNotional,
                60 days
            );
    }

    function _getSpreadConfigForImbalance(IporTypes.SpreadInputs memory spreadInputs)
        internal
        returns (ImbalanceSpreadLibs.SpreadInputData memory inputData)
    {
        inputData = ImbalanceSpreadLibs.SpreadInputData({
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
