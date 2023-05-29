// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "contracts/interfaces/IFlowsService.sol";
import "../../mocks/MockFlowsService.sol";

contract FlowsServiceBuilder is Test {

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (IFlowsService) {
        vm.startPrank(_owner);
        MockFlowsService FlowsService = new MockFlowsService();
        vm.stopPrank();
        return FlowsService;
    }
}
