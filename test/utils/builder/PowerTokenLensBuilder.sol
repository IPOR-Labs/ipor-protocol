// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "contracts/interfaces/IPowerTokenLens.sol";
import "../../mocks/MockPowerTokenLens.sol";
import "./BuilderUtils.sol";

contract PowerTokenLensBuilder is Test {

    BuilderUtils.PowerTokenLensData private _builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (IPowerTokenLens) {
        vm.startPrank(_owner);
        MockPowerTokenLens powerTokenLens = new MockPowerTokenLens(_builderData);
        vm.stopPrank();
        delete _builderData;
        return powerTokenLens;
    }
}
