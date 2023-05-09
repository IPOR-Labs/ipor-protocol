import "forge-std/Test.sol";

import "../builder/IporOracleBuilder.sol";

contract IporOracleFactory is Test {
    struct IporOracleConfig {
        address updater;
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase;
    }

    address internal _owner;

    IporOracleBuilder internal iporOracleBuilder;

    constructor(address owner) {
        _owner = owner;
        iporOracleBuilder = new IporOracleBuilder(owner, IporProtocolBuilder(address(0)));
    }

    function getInstance(
        address[] memory assets,
        address updater,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    ) public returns (ItfIporOracle) {
        iporOracleBuilder.withAssets(assets);

        (
            uint32[] memory lastUpdateTimestamps,
            uint64[] memory exponentialMovingAverages,
            uint64[] memory exponentialWeightedMovingVariances
        ) = _constructIndicatorsBasedOnInitialParamTestCase(assets, initialParamsTestCase);

        iporOracleBuilder.withLastUpdateTimestamps(lastUpdateTimestamps);
        iporOracleBuilder.withExponentialMovingAverages(exponentialMovingAverages);
        iporOracleBuilder.withExponentialWeightedMovingVariances(
            exponentialWeightedMovingVariances
        );

        ItfIporOracle iporOracle = iporOracleBuilder.build();

        vm.prank(_owner);
        iporOracle.addUpdater(updater);

        return iporOracle;
    }

    function _constructIndicatorsBasedOnInitialParamTestCase(
        address[] memory assets,
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    )
        internal
        returns (
            uint32[] memory lastUpdateTimestamps,
            uint64[] memory exponentialMovingAverages,
            uint64[] memory exponentialWeightedMovingVariances
        )
    {
        lastUpdateTimestamps = new uint32[](assets.length);
        exponentialMovingAverages = new uint64[](assets.length);
        exponentialWeightedMovingVariances = new uint64[](assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);
        uint64 exponentialMovingAverage = TestConstants.TC_DEFAULT_EMA_18DEC_64UINT;
        uint64 exponentialWeightedMovingVariance = 0;

        if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE1) {
            lastUpdateTimestamp = 1;
            exponentialMovingAverage = 1;
            exponentialWeightedMovingVariance = 1;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE2) {
            exponentialMovingAverage = 8 * 1e16;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE3) {
            exponentialMovingAverage = 50 * 1e16;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE4) {
            exponentialMovingAverage = 120 * 1e16;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE5) {
            exponentialMovingAverage = 5 * 1e16;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE6) {
            exponentialMovingAverage = 160 * 1e16;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE7) {
            exponentialMovingAverage = 0;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE8) {
            exponentialMovingAverage = 6 * 1e16;
        } else if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE9) {
            exponentialMovingAverage = 150 * 1e16;
        }

        for (uint256 i = 0; i < assets.length; i++) {
            lastUpdateTimestamps[i] = lastUpdateTimestamp;
            exponentialMovingAverages[i] = exponentialMovingAverage;
            exponentialWeightedMovingVariances[i] = exponentialWeightedMovingVariance;
        }
    }
}
