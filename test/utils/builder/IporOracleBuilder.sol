// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/oracles/IporOracle.sol";
import "forge-std/Test.sol";
import "../../mocks/EmptyIporOracleImplementation.sol";

contract IporOracleBuilder is Test {
    struct BuilderData {
        address[] assets;
        uint32[] lastUpdateTimestamps;
        address iporOracleImplementation;
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

    function withLastUpdateTimestamps(uint32[] memory lastUpdateTimestamps) public returns (IporOracleBuilder) {
        builderData.lastUpdateTimestamps = lastUpdateTimestamps;
        return this;
    }

    function withAssets(address[] memory assets) public returns (IporOracleBuilder) {
        builderData.assets = assets;
        return this;
    }

    function withIporOracleImplementation(address iporOracleImplementation) public returns (IporOracleBuilder) {
        builderData.iporOracleImplementation = iporOracleImplementation;
        return this;
    }

    function build() public returns (IporOracle) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(builderData.iporOracleImplementation));
        IporOracle iporOracle = IporOracle(address(proxy));
        vm.stopPrank();
        delete builderData;
        return iporOracle;
    }

    function buildEmptyProxy() public returns (IporOracle) {
        vm.startPrank(_owner);

        ERC1967Proxy proxy = _constructProxy(address(new EmptyIporOracleImplementation()));
        IporOracle iporOracle = IporOracle(address(proxy));
        vm.stopPrank();
        delete builderData;
        return iporOracle;
    }

    function upgrade(address iporOracleProxyAddress) public {
        vm.startPrank(_owner);

        IporOracle iporOracle = IporOracle(iporOracleProxyAddress);
        iporOracle.upgradeTo(address(builderData.iporOracleImplementation));

        vm.stopPrank();
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address[],uint32[])",
                builderData.assets,
                builderData.lastUpdateTimestamps
            )
        );
    }
}
