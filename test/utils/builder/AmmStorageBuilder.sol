// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "forge-std/Test.sol";
import "../../../contracts/chains/ethereum/amm-old/AmmStorage.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AmmStorageBuilder is Test {
    struct BuilderData {
        address iporProtocolRouter;
        address ammTreasury;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withIporProtocolRouter(address iporProtocolRouter) public returns (AmmStorageBuilder) {
        builderData.iporProtocolRouter = iporProtocolRouter;
        return this;
    }

    function withAmmTreasury(address ammTreasury) public returns (AmmStorageBuilder) {
        builderData.ammTreasury = ammTreasury;
        return this;
    }

    function build() public returns (AmmStorage) {
        require(builderData.iporProtocolRouter != address(0), "iporProtocolRouter is required");
        vm.startPrank(_owner);

        ERC1967Proxy proxy = _constructProxy(
            address(new AmmStorage(builderData.iporProtocolRouter, builderData.ammTreasury))
        );
        AmmStorage ammStorage = AmmStorage(address(proxy));
        vm.stopPrank();
        return ammStorage;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()", ""));
    }
}
