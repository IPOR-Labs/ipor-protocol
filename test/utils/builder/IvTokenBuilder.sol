// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "./BuilderUtils.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../utils/TestConstants.sol";
import "../../../contracts/tokens/IvToken.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract IvTokenBuilder is Test {
    struct BuilderData {
        string name;
        string symbol;
        address asset;
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

    function withName(string memory name) public returns (IvTokenBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (IvTokenBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withAsset(address asset) public returns (IvTokenBuilder) {
        builderData.asset = asset;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function build() public returns (IvToken) {
        vm.startPrank(_owner);
        IvToken ivToken = new IvToken(builderData.name, builderData.symbol, builderData.asset);
        vm.stopPrank();
        delete builderData;
        return ivToken;
    }
}
