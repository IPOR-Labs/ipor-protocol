// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "contracts/interfaces/IStakeService.sol";
import "../../mocks/MockStakeService.sol";

contract StakeServiceBuilder is Test {

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (IStakeService) {
        vm.startPrank(_owner);
        MockStakeService StakeService = new MockStakeService();
        vm.stopPrank();
        return StakeService;
    }
}
