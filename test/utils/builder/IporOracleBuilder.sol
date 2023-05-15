// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/itf/ItfIporOracle.sol";
import "../TestConstants.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";
import "./BuilderUtils.sol";

contract IporOracleBuilder is Test {
    struct BuilderData {
        address[] assets;
        uint32[] lastUpdateTimestamps;
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
                "initialize(address[],uint32[])",
                builderData.assets,
                builderData.lastUpdateTimestamps
            )
        );
    }
}
