// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "forge-std/Test.sol";
import "../../utils/TestConstants.sol";
import "../../../contracts/amm/spread/SpreadRouter.sol";
import "../../../contracts/amm/spread/Spread28Days.sol";
import "../../../contracts/amm/spread/Spread60Days.sol";
import "../../../contracts/amm/spread/Spread90Days.sol";
import "../../../contracts/amm/spread/SpreadStorageLens.sol";

contract SpreadRouterBuilder is Test {
    struct BuilderData {
        address iporRouter;
        address dai;
        address usdc;
        address usdt;
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withIporRouter(address iporRouter) public returns (SpreadRouterBuilder) {
        builderData.iporRouter = iporRouter;
        return this;
    }

    function withDai(address dai) public returns (SpreadRouterBuilder) {
        builderData.dai = dai;
        return this;
    }

    function withUsdc(address usdc) public returns (SpreadRouterBuilder) {
        builderData.usdc = usdc;
        return this;
    }

    function withUsdt(address usdt) public returns (SpreadRouterBuilder) {
        builderData.usdt = usdt;
        return this;
    }

    function withSpread28DaysTestCase(BuilderUtils.Spread28DaysTestCase spread28DaysTestCase)
        public
        returns (SpreadRouterBuilder)
    {
        builderData.spread28DaysTestCase = spread28DaysTestCase;
        return this;
    }

    function withSpread60DaysTestCase(BuilderUtils.Spread60DaysTestCase spread60DaysTestCase)
        public
        returns (SpreadRouterBuilder)
    {
        builderData.spread60DaysTestCase = spread60DaysTestCase;
        return this;
    }

    function withSpread90DaysTestCase(BuilderUtils.Spread90DaysTestCase spread90DaysTestCase)
        public
        returns (SpreadRouterBuilder)
    {
        builderData.spread90DaysTestCase = spread90DaysTestCase;
        return this;
    }

    function build() public returns (SpreadRouter) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(_buildImplementation());
        SpreadRouter spreadRouterProxy = SpreadRouter(address(proxy));
        vm.stopPrank();
        delete builderData;
        return spreadRouterProxy;
    }

    function _buildImplementation() internal returns (address impl) {
        SpreadRouter.DeployedContracts memory deployedContracts;
        deployedContracts.ammAddress = builderData.iporRouter;
        deployedContracts.storageLens = address(new SpreadStorageLens());
        deployedContracts.spread28Days = _buildSpread28Days();
        deployedContracts.spread60Days = _buildSpread60Days();
        deployedContracts.spread90Days = _buildSpread90Days();

        return address(new SpreadRouter(deployedContracts));
    }

    function _buildSpread28Days() internal returns (address spread) {
        if (builderData.spread28DaysTestCase == BuilderUtils.Spread28DaysTestCase.DEFAULT) {
            return address(new Spread28Days(builderData.dai, builderData.usdc, builderData.usdt));
        } else if (builderData.spread28DaysTestCase == BuilderUtils.Spread28DaysTestCase.CASE0) {
            return address(new MockSpreadXDays(TestConstants.ZERO, TestConstants.ZERO));
        } else if (builderData.spread28DaysTestCase == BuilderUtils.Spread28DaysTestCase.CASE1) {
            return address(new MockSpreadXDays(TestConstants.PERCENTAGE_4_18DEC, TestConstants.ZERO));
        } else if (builderData.spread28DaysTestCase == BuilderUtils.Spread28DaysTestCase.CASE2) {
            return address(new MockSpreadXDays(TestConstants.ZERO, TestConstants.PERCENTAGE_2_18DEC));
        }

        return address(new Spread28Days(builderData.dai, builderData.usdc, builderData.usdt));
    }

    function _buildSpread60Days() internal returns (address spread) {
        if (builderData.spread60DaysTestCase == BuilderUtils.Spread60DaysTestCase.DEFAULT) {
            return address(new Spread60Days(builderData.dai, builderData.usdc, builderData.usdt));
        } else if (builderData.spread60DaysTestCase == BuilderUtils.Spread60DaysTestCase.CASE1) {
            return address(new MockSpreadXDays(TestConstants.PERCENTAGE_6_18DEC, TestConstants.PERCENTAGE_4_18DEC));
        }

        return address(new Spread60Days(builderData.dai, builderData.usdc, builderData.usdt));
    }

    function _buildSpread90Days() internal returns (address spread) {
        if (builderData.spread90DaysTestCase == BuilderUtils.Spread90DaysTestCase.DEFAULT) {
            return address(new Spread90Days(builderData.dai, builderData.usdc, builderData.usdt));
        } else if (builderData.spread90DaysTestCase == BuilderUtils.Spread90DaysTestCase.CASE1) {
            return address(new MockSpreadXDays(TestConstants.PERCENTAGE_6_18DEC, TestConstants.PERCENTAGE_4_18DEC));
        }

        return address(new Spread90Days(builderData.dai, builderData.usdc, builderData.usdt));
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }
}
