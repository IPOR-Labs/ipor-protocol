import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../TestConstants.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";
import "./BuilderUtils.sol";

contract IporOracleBuilder is Test {
    struct BuilderData {
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase;
        address[] assets;
        uint32[] lastUpdateTimestamps;
        uint64[] exponentialMovingAverages;
        uint64[] exponentialWeightedMovingVariances;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withAsset(address asset) public returns (IporOracleBuilder) {
        builderData.assets = new address[](1);
        builderData.assets[0] = asset;
        return this;
    }

    function withLastUpdateTimestamp(uint32 lastUpdateTimestamp)
        public
        returns (IporOracleBuilder)
    {
        builderData.lastUpdateTimestamps = new uint32[](1);
        builderData.lastUpdateTimestamps[0] = lastUpdateTimestamp;
        return this;
    }

    function withExponentialMovingAverage(uint64 exponentialMovingAverage)
        public
        returns (IporOracleBuilder)
    {
        builderData.exponentialMovingAverages = new uint64[](1);
        builderData.exponentialMovingAverages[0] = exponentialMovingAverage;
        return this;
    }

    function withExponentialWeightedMovingVariance(uint64 exponentialWeightedMovingVariance)
        public
        returns (IporOracleBuilder)
    {
        builderData.exponentialWeightedMovingVariances = new uint64[](1);
        builderData.exponentialWeightedMovingVariances[0] = exponentialWeightedMovingVariance;
        return this;
    }

    function withAssets(address[] memory assets) public returns (IporOracleBuilder) {
        builderData.assets = assets;
        return this;
    }

    function withInitialParamsTestCase(
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    ) public returns (IporOracleBuilder) {
        builderData.initialParamsTestCase = initialParamsTestCase;
        return this;
    }

    function _buildIndicatorsBasedOnInitialParamTestCase() internal {
        builderData.lastUpdateTimestamps = new uint32[](builderData.assets.length);
        builderData.exponentialMovingAverages = new uint64[](builderData.assets.length);
        builderData.exponentialWeightedMovingVariances = new uint64[](builderData.assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);
        uint64 exponentialMovingAverage = TestConstants.TC_DEFAULT_EMA_18DEC_64UINT;
        uint64 exponentialWeightedMovingVariance = 0;

        if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE1
        ) {
            lastUpdateTimestamp = 1;
            exponentialMovingAverage = 1;
            exponentialWeightedMovingVariance = 1;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE2
        ) {
            exponentialMovingAverage = 8 * 1e16;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE3
        ) {
            exponentialMovingAverage = 50 * 1e16;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE4
        ) {
            exponentialMovingAverage = 120 * 1e16;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE5
        ) {
            exponentialMovingAverage = 5 * 1e16;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE6
        ) {
            exponentialMovingAverage = 160 * 1e16;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE7
        ) {
            exponentialMovingAverage = 0;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE8
        ) {
            exponentialMovingAverage = 6 * 1e16;
        } else if (
            builderData.initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE9
        ) {
            exponentialMovingAverage = 150 * 1e16;
        }

        for (uint256 i = 0; i < builderData.assets.length; i++) {
            builderData.lastUpdateTimestamps[i] = lastUpdateTimestamp;
            builderData.exponentialMovingAverages[i] = exponentialMovingAverage;
            builderData.exponentialWeightedMovingVariances[i] = exponentialWeightedMovingVariance;
        }
    }

    function build() public returns (ItfIporOracle) {
        vm.startPrank(_owner);
        _buildIndicatorsBasedOnInitialParamTestCase();
        ERC1967Proxy proxy = _constructProxy(address(new ItfIporOracle()));
        ItfIporOracle iporOracle = ItfIporOracle(address(proxy));
        vm.stopPrank();
        return iporOracle;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address[],uint32[],uint64[],uint64[])",
                builderData.assets,
                builderData.lastUpdateTimestamps,
                builderData.exponentialMovingAverages,
                builderData.exponentialWeightedMovingVariances
            )
        );
    }
}
