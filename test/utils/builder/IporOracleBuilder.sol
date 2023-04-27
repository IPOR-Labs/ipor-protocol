import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract IporOracleBuilder {
    struct BuilderData {
        address[] memory assets;
        uint32[] memory lastUpdateTimestamps;
        uint64[] memory exponentialMovingAverages;
        uint64[] memory exponentialWeightedMovingVariances;
    }

    BuilderData private builderData;

    constructor(address asset) {
        default(asset);
    }

    function default(address asset) public returns (IporOracleBuilder) {
        return withAsset(asset);
    }

    function withAsset(address asset) public returns (IporOracleBuilder) {

        return this;
    }

    function withAllAssets() public returns (IporOracleBuilder) {
        return this;
    }

    function build() public returns (ItfIporOracle) {
        ERC1967Proxy iporOracleProxy = _constructProxy(address(new ItfIporOracle()));
        return ItfIporOracle(iporOracleProxy);
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address[],uint32[],uint64[],uint64[])",
                builderData.tokenAddresses,
                builderData.lastUpdateTimestamps,
                builderData.exponentialMovingAverages,
                builderData.exponentialWeightedMovingVariances
            )
        );
    }
}
