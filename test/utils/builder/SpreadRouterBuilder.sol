// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "forge-std/Test.sol";

contract SpreadRouterBuilder is Test {
    struct BuilderData {
        BuilderUtils.Spread28DaysTestCase spread28DaysTestCase;
        BuilderUtils.Spread60DaysTestCase spread60DaysTestCase;
        BuilderUtils.Spread90DaysTestCase spread90DaysTestCase;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withSpread28DaysTestCase(BuilderUtils.Spread28DaysTestCase memory spread28DaysTestCase)
        public
        returns (MockSpreadRouterBuilder)
    {
        builderData.spread28DaysTestCase = spread28DaysTestCase;
        return this;
    }

    function withSpread60DaysTestCase(BuilderUtils.Spread60DaysTestCase memory spread60DaysTestCase)
        public
        returns (MockSpreadRouterBuilder)
    {
        builderData.spread60DaysTestCase = spread60DaysTestCase;
        return this;
    }

    function withSpread90DaysTestCase(BuilderUtils.Spread90DaysTestCase memory spread90DaysTestCase)
        public
        returns (MockSpreadRouterBuilder)
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
        return milton;
    }

    function _buildImplementation() internal returns (address impl) {
        SpreadRouter.DeployedContracts deployedContracts = SpreadRouter.DeployedContracts({

        });
        return address(new SpreadRouter(deployedContracts));
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }
}
