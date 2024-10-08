// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "forge-std/Test.sol";
import "../../../contracts/interfaces/IPowerTokenStakeService.sol";
import "../../mocks/MockPowerTokenStakeService.sol";

contract PowerTokenStakeServiceBuilder is Test {

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (IPowerTokenStakeService) {
        vm.startPrank(_owner);
        MockPowerTokenStakeService StakeService = new MockPowerTokenStakeService();
        vm.stopPrank();
        return StakeService;
    }
}
