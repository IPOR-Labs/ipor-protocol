// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "forge-std/Test.sol";
import "@ipor-protocol/contracts/interfaces/ILiquidityMiningLens.sol";
import "@ipor-protocol/test/mocks/MockLiquidityMiningLens.sol";

contract LiquidityMiningLensBuilder is Test {

    BuilderUtils.LiquidityMiningLensData private _builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (ILiquidityMiningLens) {
        vm.startPrank(_owner);
        MockLiquidityMiningLens LiquidityMiningLens = new MockLiquidityMiningLens(_builderData);
        vm.stopPrank();
        delete _builderData;
        return LiquidityMiningLens;
    }
}
