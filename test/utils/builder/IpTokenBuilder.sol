// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "forge-std/Test.sol";
import "contracts/tokens/IpToken.sol";

contract IpTokenBuilder is Test {
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

    function withName(string memory name) public returns (IpTokenBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (IpTokenBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withAsset(address asset) public returns (IpTokenBuilder) {
        builderData.asset = asset;
        return this;
    }

    function build() public returns (IpToken) {
        vm.startPrank(_owner);
        IpToken ipToken = new IpToken(builderData.name, builderData.symbol, builderData.asset);
        vm.stopPrank();
        delete builderData;
        return ipToken;
    }
}
