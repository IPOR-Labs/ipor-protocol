// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "./BuilderUtils.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "../../utils/TestConstants.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract MockSpreadBuilder is Test {
    struct BuilderData {
        uint256 quotePayFixedValue;
        uint256 quoteReceiveFixedValue;
        int256 spreadPayFixedValue;
        int256 spreadReceiveFixedValue;
        address spreadImplementation;
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

    function withQuotePayFixedValue(uint256 quotePayFixedValue) public returns (MockSpreadBuilder) {
        builderData.quotePayFixedValue = quotePayFixedValue;
        return this;
    }

    function withQuoteReceiveFixedValue(uint256 quoteReceiveFixedValue) public returns (MockSpreadBuilder) {
        builderData.quoteReceiveFixedValue = quoteReceiveFixedValue;
        return this;
    }

    function withSpreadPayFixedValue(int256 spreadPayFixedValue) public returns (MockSpreadBuilder) {
        builderData.spreadPayFixedValue = spreadPayFixedValue;
        return this;
    }

    function withSpreadReceiveFixedValue(int256 spreadReceiveFixedValue) public returns (MockSpreadBuilder) {
        builderData.spreadReceiveFixedValue = spreadReceiveFixedValue;
        return this;
    }

    function withSpreadImplementation(address spreadImplementation) public returns (MockSpreadBuilder) {
        builderData.spreadImplementation = spreadImplementation;
        return this;
    }

    function build() public returns (MockSpreadModel spreadModel) {
        vm.startPrank(_owner);
        if (builderData.spreadImplementation != address(0)) {
            spreadModel = MockSpreadModel(builderData.spreadImplementation);
        } else {
            spreadModel = new MockSpreadModel(
                builderData.quotePayFixedValue,
                builderData.quoteReceiveFixedValue,
                builderData.spreadPayFixedValue,
                builderData.spreadReceiveFixedValue
            );
        }
        vm.stopPrank();
        delete builderData;
    }
}
