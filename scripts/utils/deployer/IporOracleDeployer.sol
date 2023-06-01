// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./DeployerUtils.sol";
import "../../../test/utils/TestConstants.sol";
import "scripts/mocks/EmptyIporOracleImplementation.sol";

contract IporOracleDeployer {
    struct DeployerData {
        address[] assets;
        uint32[] lastUpdateTimestamps;
        address iporOracleImplementation;
    }

    DeployerData private deployerData;

    function withAsset(address asset) public returns (IporOracleDeployer) {
        deployerData.assets = new address[](1);
        deployerData.assets[0] = asset;
        return this;
    }

    function withLastUpdateTimestamp(uint32 lastUpdateTimestamp) public returns (IporOracleDeployer) {
        deployerData.lastUpdateTimestamps = new uint32[](1);
        deployerData.lastUpdateTimestamps[0] = lastUpdateTimestamp;
        return this;
    }

    function withLastUpdateTimestamps(uint32[] memory lastUpdateTimestamps) public returns (IporOracleDeployer) {
        deployerData.lastUpdateTimestamps = lastUpdateTimestamps;
        return this;
    }

    function withAssets(address[] memory assets) public returns (IporOracleDeployer) {
        deployerData.assets = assets;
        return this;
    }

    function withIporOracleImplementation(address iporOracleImplementation) public returns (IporOracleDeployer) {
        deployerData.iporOracleImplementation = iporOracleImplementation;
        return this;
    }

    function build() public returns (IporOracle) {
        ERC1967Proxy proxy = _constructProxy(address(deployerData.iporOracleImplementation));
        IporOracle iporOracle = IporOracle(address(proxy));
        return iporOracle;
    }

    function buildEmptyProxy() public returns (IporOracle) {
        ERC1967Proxy proxy = _constructProxy(address(new EmptyIporOracleImplementation()));
        IporOracle iporOracle = IporOracle(address(proxy));
        return iporOracle;
    }

    function upgrade(address iporOracleProxyAddress) public {
        IporOracle iporOracle = IporOracle(iporOracleProxyAddress);
        iporOracle.upgradeTo(address(deployerData.iporOracleImplementation));
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address[],uint32[])",
                deployerData.assets,
                deployerData.lastUpdateTimestamps
            )
        );
    }
}
