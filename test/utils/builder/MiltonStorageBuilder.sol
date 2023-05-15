// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./BuilderUtils.sol";
import "../../../contracts/amm/MiltonStorage.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../utils/TestConstants.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract MiltonStorageBuilder is Test{
    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
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
