// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "contracts/interfaces/ILiquidityMiningLens.sol";
import "../../mocks/MockLiquidityMiningLens.sol";

contract LiquidityMiningLensBuilder is Test {

    BuilderUtils.LiquidityMiningLensData private _builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withContractId(bytes32 contractId) public returns (LiquidityMiningLensBuilder) {
        _builderData.contractId = contractId;
        return this;
    }

    function build() public returns (ILiquidityMiningLens) {
        vm.startPrank(_owner);
        MockLiquidityMiningLens LiquidityMiningLens = new MockLiquidityMiningLens(_builderData);
        vm.stopPrank();
        delete _builderData;
        return LiquidityMiningLens;
    }
}
