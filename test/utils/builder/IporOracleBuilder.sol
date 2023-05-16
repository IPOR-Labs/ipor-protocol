// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/itf/ItfIporOracle.sol";
import "../TestConstants.sol";
import "forge-std/Test.sol";
import "./BuilderUtils.sol";

contract IporOracleBuilder is Test {
    struct BuilderData {
        address[] assets;
        uint32[] lastUpdateTimestamps;
        uint64[] exponentialMovingAverages;
        uint64[] exponentialWeightedMovingVariances;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAsset(address asset) public returns (IporOracleBuilder) {
        builderData.assets = new address[](1);
        builderData.assets[0] = asset;
        return this;
    }

    function withLastUpdateTimestamp(uint32 lastUpdateTimestamp) public returns (IporOracleBuilder) {
        builderData.lastUpdateTimestamps = new uint32[](1);
        builderData.lastUpdateTimestamps[0] = lastUpdateTimestamp;
        return this;
    }

    function withExponentialMovingAverage(uint64 exponentialMovingAverage) public returns (IporOracleBuilder) {
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

    function withLastUpdateTimestamps(uint32[] memory lastUpdateTimestamps) public returns (IporOracleBuilder) {
        builderData.lastUpdateTimestamps = lastUpdateTimestamps;
        return this;
    }

    function withExponentialMovingAverages(uint64[] memory exponentialMovingAverages)
        public
        returns (IporOracleBuilder)
    {
        builderData.exponentialMovingAverages = exponentialMovingAverages;
        return this;
    }

    function withExponentialWeightedMovingVariances(uint64[] memory exponentialWeightedMovingVariances)
        public
        returns (IporOracleBuilder)
    {
        builderData.exponentialWeightedMovingVariances = exponentialWeightedMovingVariances;
        return this;
    }

    function withAssets(address[] memory assets) public returns (IporOracleBuilder) {
        builderData.assets = assets;
        return this;
    }

    function build() public returns (ItfIporOracle) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new ItfIporOracle()));
        ItfIporOracle iporOracle = ItfIporOracle(address(proxy));
        vm.stopPrank();
        delete builderData;
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
