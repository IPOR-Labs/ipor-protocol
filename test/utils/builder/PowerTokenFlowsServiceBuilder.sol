// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "forge-std/Test.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenFlowsService.sol";
import "@ipor-protocol/test/mocks/MockPowerTokenFlowsService.sol";

contract PowerTokenFlowsServiceBuilder is Test {

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (IPowerTokenFlowsService) {
        vm.startPrank(_owner);
        MockPowerTokenFlowsService FlowsService = new MockPowerTokenFlowsService();
        vm.stopPrank();
        return FlowsService;
    }
}
