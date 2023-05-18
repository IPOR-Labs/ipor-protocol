// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "forge-std/Test.sol";
import "../../../contracts/amm/MiltonStorage.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MiltonStorageBuilder is Test {
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function build() public returns (MiltonStorage) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new MiltonStorage()));
        MiltonStorage miltonStorage = MiltonStorage(address(proxy));
        vm.stopPrank();
        return miltonStorage;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        proxy = new ERC1967Proxy(address(impl), abi.encodeWithSignature("initialize()", ""));
    }
}