// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "forge-std/Test.sol";
import "../../../contracts/interfaces/ILiquidityMiningLens.sol";
import "../../mocks/MockLiquidityMiningLens.sol";

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
