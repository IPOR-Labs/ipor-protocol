// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "forge-std/Test.sol";
import "../../utils/TestConstants.sol";
import "../../mocks/EmptyImplementation.sol";
import "../../../contracts/router/IporProtocolRouter.sol";
contract IporProtocolRouterBuilder is Test {
//    struct BuilderData {
//        ;
//    }
//
//    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function buildEmptyProxy() public returns (IporProtocolRouter) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new EmptyImplementation()));
        IporProtocolRouter iporProtocolRouter = IporProtocolRouter(address(proxy));
        vm.stopPrank();
//        delete builderData;
        return iporProtocolRouter;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize(bool)", false));
    }
}

