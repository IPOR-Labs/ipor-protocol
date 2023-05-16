// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/oracles/IporRiskManagementOracle.sol";
import "../TestConstants.sol";
import "forge-std/Test.sol";
import "./BuilderUtils.sol";

contract IporRiskManagementOracleBuilder is Test {
    struct BuilderData {
        address[] assets;
        uint256[] maxNotionalPayFixed;
        uint256[] maxNotionalReceiveFixed;
        uint256[] maxUtilizationRatePayFixed;
        uint256[] maxUtilizationRateReceiveFixed;
        uint256[] maxUtilizationRate;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAsset(address asset) public returns (IporRiskManagementOracleBuilder) {
        builderData.assets = new address[](1);
        builderData.assets[0] = asset;
        return this;
    }

    function withMaxNotionalPayFixed(uint256 maxNotionalPayFixed) public returns (IporRiskManagementOracleBuilder) {
        builderData.maxNotionalPayFixed = new uint256[](1);
        builderData.maxNotionalPayFixed[0] = maxNotionalPayFixed;
        return this;
    }

    function withMaxNotionalReceiveFixed(uint256 maxNotionalReceiveFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxNotionalReceiveFixed = new uint256[](1);
        builderData.maxNotionalReceiveFixed[0] = maxNotionalReceiveFixed;
        return this;
    }

    function withMaxUtilizationRatePayFixed(uint256 maxUtilizationRatePayFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxUtilizationRatePayFixed = new uint256[](1);
        builderData.maxUtilizationRatePayFixed[0] = maxUtilizationRatePayFixed;
        return this;
    }

    function withMaxUtilizationRateReceiveFixed(uint256 maxUtilizationRateReceiveFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxUtilizationRateReceiveFixed = new uint256[](1);
        builderData.maxUtilizationRateReceiveFixed[0] = maxUtilizationRateReceiveFixed;
        return this;
    }

    function withMaxUtilizationRate(uint256 maxUtilizationRate) public returns (IporRiskManagementOracleBuilder) {
        builderData.maxUtilizationRate = new uint256[](1);
        builderData.maxUtilizationRate[0] = maxUtilizationRate;
        return this;
    }

    function withAssets(address[] memory assets) public returns (IporRiskManagementOracleBuilder) {
        builderData.assets = assets;
        return this;
    }

    function withMaxNotionalPayFixeds(uint256[] memory maxNotionalPayFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxNotionalPayFixed = maxNotionalPayFixed;
        return this;
    }

    function withMaxNotionalReceiveFixeds(uint256[] memory maxNotionalReceiveFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxNotionalReceiveFixed = maxNotionalReceiveFixed;
        return this;
    }

    function withMaxUtilizationRatePayFixeds(uint256[] memory maxUtilizationRatePayFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxUtilizationRatePayFixed = maxUtilizationRatePayFixed;
        return this;
    }

    function withMaxUtilizationRateReceiveFixeds(uint256[] memory maxUtilizationRateReceiveFixed)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxUtilizationRateReceiveFixed = maxUtilizationRateReceiveFixed;
        return this;
    }

    function withMaxUtilizationRates(uint256[] memory maxUtilizationRate)
        public
        returns (IporRiskManagementOracleBuilder)
    {
        builderData.maxUtilizationRate = maxUtilizationRate;
        return this;
    }

    function build() public returns (IporRiskManagementOracle) {
        require(
            builderData.maxNotionalPayFixed.length == builderData.assets.length,
            "Builder: maxNotionalPayFixed length mismatch"
        );
        require(
            builderData.maxNotionalReceiveFixed.length == builderData.assets.length,
            "Builder: maxNotionalReceiveFixed length mismatch"
        );
        require(
            builderData.maxUtilizationRatePayFixed.length == builderData.assets.length,
            "Builder: maxUtilizationRatePayFixed length mismatch"
        );
        require(
            builderData.maxUtilizationRateReceiveFixed.length == builderData.assets.length,
            "Builder: maxUtilizationRateReceiveFixed length mismatch"
        );
        require(
            builderData.maxUtilizationRate.length == builderData.assets.length,
            "Builder: maxUtilizationRate length mismatch"
        );

        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new IporRiskManagementOracle()));
        IporRiskManagementOracle oracle = IporRiskManagementOracle(address(proxy));
        vm.stopPrank();
        delete builderData;
        return oracle;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address[],uint256[],uint256[],uint256[],uint256[],uint256[])",
                builderData.assets,
                builderData.maxNotionalPayFixed,
                builderData.maxNotionalReceiveFixed,
                builderData.maxUtilizationRatePayFixed,
                builderData.maxUtilizationRateReceiveFixed,
                builderData.maxUtilizationRate
            )
        );
    }
}
