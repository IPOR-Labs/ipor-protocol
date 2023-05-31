// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/console2.sol";
import "forge-std/Test.sol";
import "../TestConstants.sol";
import "../builder/IporRiskManagementOracleBuilder.sol";

contract IporRiskManagementOracleFactory is Test {
    address internal _owner;

    IporRiskManagementOracleBuilder internal _iporRiskManagementOracleBuilder;

    constructor(address owner) {
        _owner = owner;
        _iporRiskManagementOracleBuilder = new IporRiskManagementOracleBuilder(owner);
    }

    function getInstance(
        address[] memory assets,
        address updater,
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase initialParams
    ) public returns (IporRiskManagementOracle) {
        IporRiskManagementOracleTypes.RiskIndicators
            memory riskIndicators = _constructIndicatorsBasedOnInitialParamTestCase(initialParams);

        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps
            memory baseSpreadsAndFixedRateCaps = _constructSpreadsBasedOnInitialParamTestCase(initialParams);

        for (uint256 i = 0; i < assets.length; i++) {
            _iporRiskManagementOracleBuilder.withAsset(assets[i], riskIndicators, baseSpreadsAndFixedRateCaps);
        }

        IporRiskManagementOracle oracle = _iporRiskManagementOracleBuilder.build();

        vm.prank(_owner);
        oracle.addUpdater(updater);

        return oracle;
    }

    function _constructIndicatorsBasedOnInitialParamTestCase(
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase initialParamsTestCase
    ) internal view returns (IporRiskManagementOracleTypes.RiskIndicators memory riskIndicators) {
        //TODO: pure
        uint64 maxNotionalPayFixed = TestConstants.RMO_NOTIONAL_1B;
        uint64 maxNotionalReceiveFixed = TestConstants.RMO_NOTIONAL_1B;
        uint16 maxUtilizationRatePayFixed = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        uint16 maxUtilizationRateReceiveFixed = TestConstants.RMO_UTILIZATION_RATE_48_PER;
        uint16 maxUtilizationRate = TestConstants.RMO_UTILIZATION_RATE_90_PER;

        if (initialParamsTestCase == BuilderUtils.IporRiskManagementOracleInitialParamsTestCase.CASE1) {
            maxUtilizationRatePayFixed = 0;
            maxUtilizationRateReceiveFixed = 0;
            maxUtilizationRate = 0;
        } else if (initialParamsTestCase == BuilderUtils.IporRiskManagementOracleInitialParamsTestCase.CASE2) {
            maxNotionalPayFixed = 0;
            maxNotionalReceiveFixed = 0;

            maxUtilizationRatePayFixed = TestConstants.RMO_UTILIZATION_RATE_20_PER;
            maxUtilizationRateReceiveFixed = TestConstants.RMO_UTILIZATION_RATE_20_PER;
            maxUtilizationRate = TestConstants.RMO_UTILIZATION_RATE_20_PER;
        } else if (initialParamsTestCase == BuilderUtils.IporRiskManagementOracleInitialParamsTestCase.CASE3) {
            maxNotionalPayFixed = type(uint64).max;
            maxNotionalReceiveFixed = type(uint64).max;

            maxUtilizationRatePayFixed = TestConstants.RMO_UTILIZATION_RATE_20_PER;
            maxUtilizationRateReceiveFixed = TestConstants.RMO_UTILIZATION_RATE_20_PER;
            maxUtilizationRate = TestConstants.RMO_UTILIZATION_RATE_20_PER;
        } else if (initialParamsTestCase == BuilderUtils.IporRiskManagementOracleInitialParamsTestCase.CASE4) {
            maxNotionalPayFixed = type(uint64).max;
            maxNotionalReceiveFixed = type(uint64).max;

            maxUtilizationRatePayFixed = TestConstants.RMO_UTILIZATION_RATE_MAX;
            maxUtilizationRateReceiveFixed = TestConstants.RMO_UTILIZATION_RATE_MAX;
            maxUtilizationRate = TestConstants.RMO_UTILIZATION_RATE_MAX;
        } else if (initialParamsTestCase == BuilderUtils.IporRiskManagementOracleInitialParamsTestCase.CASE5) {
            maxUtilizationRatePayFixed = TestConstants.RMO_UTILIZATION_RATE_30_PER;
            maxUtilizationRateReceiveFixed = TestConstants.RMO_UTILIZATION_RATE_30_PER;
            maxUtilizationRate = TestConstants.RMO_UTILIZATION_RATE_80_PER;
        } else if (initialParamsTestCase == BuilderUtils.IporRiskManagementOracleInitialParamsTestCase.CASE6) {
            maxUtilizationRatePayFixed = TestConstants.RMO_UTILIZATION_RATE_48_PER;
            maxUtilizationRateReceiveFixed = TestConstants.RMO_UTILIZATION_RATE_48_PER;
            maxUtilizationRate = TestConstants.RMO_UTILIZATION_RATE_80_PER;
        }

        return
            IporRiskManagementOracleTypes.RiskIndicators({
                maxNotionalPayFixed: maxNotionalPayFixed,
                maxNotionalReceiveFixed: maxNotionalReceiveFixed,
                maxUtilizationRatePayFixed: maxUtilizationRatePayFixed,
                maxUtilizationRateReceiveFixed: maxUtilizationRateReceiveFixed,
                maxUtilizationRate: maxUtilizationRate
            });
    }

    function _constructSpreadsBasedOnInitialParamTestCase(
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase initialParamsTestCase
    ) internal pure returns (IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps memory baseSpreads) {
        int24 spread28dPayFixed = TestConstants.RMO_SPREAD_0_1_PER;
        int24 spread28dReceiveFixed = TestConstants.RMO_SPREAD_0_1_PER;
        int24 spread60dPayFixed = TestConstants.RMO_SPREAD_0_1_PER;
        int24 spread60dReceiveFixed = TestConstants.RMO_SPREAD_0_1_PER;
        int24 spread90dPayFixed = TestConstants.RMO_SPREAD_0_1_PER;
        int24 spread90dReceiveFixed = TestConstants.RMO_SPREAD_0_1_PER;
        uint16 fixedRateCap28dPayFixed = TestConstants.RMO_FIXED_RATE_CAP_2_0_PER;
        uint16 fixedRateCap28dReceiveFixed = TestConstants.RMO_FIXED_RATE_CAP_3_5_PER;
        uint16 fixedRateCap60dPayFixed = TestConstants.RMO_FIXED_RATE_CAP_2_0_PER;
        uint16 fixedRateCap60dReceiveFixed = TestConstants.RMO_FIXED_RATE_CAP_3_5_PER;
        uint16 fixedRateCap90dPayFixed = TestConstants.RMO_FIXED_RATE_CAP_2_0_PER;
        uint16 fixedRateCap90dReceiveFixed = TestConstants.RMO_FIXED_RATE_CAP_3_5_PER;

        return
            IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps({
                spread28dPayFixed: spread28dPayFixed,
                spread28dReceiveFixed: spread28dReceiveFixed,
                spread60dPayFixed: spread60dPayFixed,
                spread60dReceiveFixed: spread60dReceiveFixed,
                spread90dPayFixed: spread90dPayFixed,
                spread90dReceiveFixed: spread90dReceiveFixed,
                fixedRateCap28dPayFixed: fixedRateCap28dPayFixed,
                fixedRateCap28dReceiveFixed: fixedRateCap28dReceiveFixed,
                fixedRateCap60dPayFixed: fixedRateCap60dPayFixed,
                fixedRateCap60dReceiveFixed: fixedRateCap60dReceiveFixed,
                fixedRateCap90dPayFixed: fixedRateCap90dPayFixed,
                fixedRateCap90dReceiveFixed: fixedRateCap90dReceiveFixed
            });
    }
}
