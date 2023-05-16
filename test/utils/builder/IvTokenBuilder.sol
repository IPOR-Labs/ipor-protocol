// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "contracts/tokens/IvToken.sol";

contract IvTokenBuilder is Test {
    struct BuilderData {
        string name;
        string symbol;
        address asset;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
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
