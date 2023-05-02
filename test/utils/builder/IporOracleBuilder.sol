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

    function withDefaultIndicators() public returns (IporOracleBuilder) {
        builderData.lastUpdateTimestamps = new uint32[](builderData.assets.length);
        builderData.exponentialMovingAverages = new uint64[](builderData.assets.length);
        builderData.exponentialWeightedMovingVariances = new uint64[](builderData.assets.length);
        for (uint256 i = 0; i < builderData.assets.length; i++) {
            builderData.lastUpdateTimestamps[i] = uint32(block.timestamp);
            builderData.exponentialMovingAverages[i] = TestConstants.TC_DEFAULT_EMA_18DEC_64UINT;
            builderData.exponentialWeightedMovingVariances[i] = 0;
        }
        return this;
    }

    function withInitialParamsTestCase(
        BuilderUtils.IporOracleInitialParamsTestCase initialParamsTestCase
    ) public returns (IporOracleBuilder) {
        builderData.initialParamsTestCase = initialParamsTestCase;

        if (initialParamsTestCase == BuilderUtils.IporOracleInitialParamsTestCase.CASE1) {
            withLastUpdateTimestamp(1);
            withExponentialMovingAverage(1);
            withExponentialWeightedMovingVariance(1);
        } else {
            withDefaultIndicators();
        }

        return this;
    }

    function build() public returns (ItfIporOracle) {
        vm.startPrank(_owner);
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
