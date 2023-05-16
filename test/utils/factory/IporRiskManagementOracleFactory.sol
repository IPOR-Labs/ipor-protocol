// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "../TestConstants.sol";
import "../builder/IporRiskManagementOracleBuilder.sol";

contract IporRiskManagementOracleFactory is Test {
    address internal _owner;

    IporRiskManagementOracleBuilder internal _iporRiskManagementOracleBuilder;

    constructor(address owner) {
        _owner = owner;
        _iporRiskManagementOracleBuilder = new IporRiskManagementOracleBuilder(owner, IporProtocolBuilder(address(0)));
    }

    function getInstance(
        address[] memory assets,
        address updater,
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase initialParams
    ) public returns (IporRiskManagementOracle) {
        _iporRiskManagementOracleBuilder.withAssets(assets);

        (
            uint256[] memory maxNotionalPayFixed,
            uint256[] memory maxNotionalReceiveFixed,
            uint256[] memory maxUtilizationRatePayFixed,
            uint256[] memory maxUtilizationRateReceiveFixed,
            uint256[] memory maxUtilizationRate
        ) = _constructIndicatorsBasedOnInitialParamTestCase(assets, initialParams);

        _iporRiskManagementOracleBuilder.withMaxNotionalPayFixeds(maxNotionalPayFixed);
        _iporRiskManagementOracleBuilder.withMaxNotionalReceiveFixeds(maxNotionalReceiveFixed);
        _iporRiskManagementOracleBuilder.withMaxUtilizationRatePayFixeds(maxUtilizationRatePayFixed);
        _iporRiskManagementOracleBuilder.withMaxUtilizationRateReceiveFixeds(maxUtilizationRateReceiveFixed);
        _iporRiskManagementOracleBuilder.withMaxUtilizationRates(maxUtilizationRate);

        IporRiskManagementOracle oracle = _iporRiskManagementOracleBuilder.build();

        vm.prank(_owner);
        oracle.addUpdater(updater);

        return oracle;
    }

    function _constructIndicatorsBasedOnInitialParamTestCase(
        address[] memory assets,
        BuilderUtils.IporRiskManagementOracleInitialParamsTestCase initialParamsTestCase
    )
        internal
        pure
        returns (
            uint256[] memory maxNotionalPayFixedList,
            uint256[] memory maxNotionalReceiveFixedList,
            uint256[] memory maxUtilizationRatePayFixedList,
            uint256[] memory maxUtilizationRateReceiveFixedList,
            uint256[] memory maxUtilizationRateList
        )
    {
        maxNotionalPayFixedList = new uint256[](assets.length);
        maxNotionalReceiveFixedList = new uint256[](assets.length);
        maxUtilizationRatePayFixedList = new uint256[](assets.length);
        maxUtilizationRateReceiveFixedList = new uint256[](assets.length);
        maxUtilizationRateList = new uint256[](assets.length);

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

        for (uint256 i = 0; i < assets.length; i++) {
            maxNotionalPayFixedList[i] = maxNotionalPayFixed;
            maxNotionalReceiveFixedList[i] = maxNotionalReceiveFixed;
            maxUtilizationRatePayFixedList[i] = maxUtilizationRatePayFixed;
            maxUtilizationRateReceiveFixedList[i] = maxUtilizationRateReceiveFixed;
            maxUtilizationRateList[i] = maxUtilizationRate;
        }
    }
}
