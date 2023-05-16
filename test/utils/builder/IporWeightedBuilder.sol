// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/mocks/MockIporWeighted.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract IporWeightedBuilder is Test {
    struct BuilderData {
        address iporOracle;
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

    function withIporOracle(address iporOracle) public returns (IporWeightedBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function isSetIporOracle() public view returns (bool) {
        return builderData.iporOracle != address(0);
    }

    function build() public returns (MockIporWeighted) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MockIporWeighted()));
        MockIporWeighted iporWeighted = MockIporWeighted(address(proxy));
        vm.stopPrank();
        delete builderData;
        return iporWeighted;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(impl, abi.encodeWithSignature("initialize(address)", builderData.iporOracle));
    }
}
