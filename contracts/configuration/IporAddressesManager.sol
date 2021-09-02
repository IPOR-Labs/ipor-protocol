// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IIporAddressesManager.sol";
//TODO: clarify if better is to have external libraries in local folder
import "@openzeppelin/contracts/access/Ownable.sol";

contract IporAddressesManager is Ownable, IIporAddressesManager {

    mapping(string => address) private _addresses;

    //this treasurer manage ipor publication fee balance, key is an asset
    mapping(string => address) charlieTreasurers;
    //this treasurer manage opening fee balance, key is an asset
    mapping(string => address) treasureTreasurers;

    string private constant WARREN = "WARREN";
    string private constant MILTON = "MILTON";
    string private constant MILTON_STORAGE = "MILTON_STORAGE";
    string private constant MILTON_CONFIGURATION = "MILTON_CONFIGURATION";


    function setAddressAsProxy(string memory id, address implementationAddress)
    external
    override
    onlyOwner
    {
        _updateImpl(id, implementationAddress);
        emit AddressSet(id, implementationAddress, true);
    }

    function setAddress(string memory id, address newAddress) external override onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    function getAddress(string memory id) public view override returns (address) {
        return _addresses[id];
    }

    function getMilton() external view override returns (address) {
        return getAddress(MILTON);
    }

    //TODO: implement _updateImpl and then use this method
    function setMiltonImpl(address miltonImpl) external override onlyOwner {
        _updateImpl(MILTON, miltonImpl);
        emit MiltonAddressUpdated(miltonImpl);
    }

    function getMiltonStorage() external view override returns (address) {
        return getAddress(MILTON_STORAGE);
    }

    function setMiltonStorageImpl(address miltonStorageImpl) external override onlyOwner {
        _updateImpl(MILTON_STORAGE, miltonStorageImpl);
        emit MiltonStorageAddressUpdated(miltonStorageImpl);
    }

    function getMiltonConfiguration() external view override returns (address) {
        return getAddress(MILTON_CONFIGURATION);
    }

    //TODO: implement _updateImpl and then use this method
    function setMiltonConfigurationImpl(address miltonConfigImpl) external override onlyOwner {
        _updateImpl(MILTON_CONFIGURATION, miltonConfigImpl);
        emit MiltonConfigurationAddressUpdated(miltonConfigImpl);
    }

    function getWarren() external view override returns (address) {
        return getAddress(WARREN);
    }

    //TODO: implement _updateImpl and then use this method
    function setWarrenImpl(address warrenImpl) external override onlyOwner {
        _updateImpl(WARREN, warrenImpl);
        emit WarrenAddressUpdated(warrenImpl);
    }

    function getCharlieTreasurer(string memory asset) external override view returns (address) {
        return charlieTreasurers[asset];
    }

    function setCharlieTreasurer(string memory asset, address _charlieTreasurer) external override onlyOwner {
        charlieTreasurers[asset] = _charlieTreasurer;
        emit CharlieTreasurerUpdated(asset, _charlieTreasurer);
    }

    function getTreasureTreasurer(string memory asset) external override view returns (address) {
        return treasureTreasurers[asset];
    }

    function setTreasureTreasurer(string memory asset, address _treasureTreasurer) external override onlyOwner {
        treasureTreasurers[asset] = _treasureTreasurer;
        emit TreasureTreasurerUpdated(asset, _treasureTreasurer);
    }

    //TODO: verify it, inspired by Aave
    function _updateImpl(string memory id, address newAddress) internal {
        //TODO: tailor to ipor solution (immutable admin maybe not needed)
        //TODO: implement proxy, upgradable contracts
        //        address payable proxyAddress = payable(_addresses[id]);
        //
        //        InitializableImmutableAdminUpgradeabilityProxy proxy =
        //        InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
        //        bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));
        //
        //        if (proxyAddress == address(0)) {
        //            proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
        //            proxy.initialize(newAddress, params);
        //            _addresses[id] = address(proxy);
        //            emit ProxyCreated(id, address(proxy));
        //        } else {
        //            proxy.upgradeToAndCall(newAddress, params);
        //        }
    }

}