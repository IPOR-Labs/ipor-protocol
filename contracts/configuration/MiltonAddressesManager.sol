// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IMiltonAddressesManager.sol";
//TODO: clarify if better is to have external libraries in local folder
import "@openzeppelin/contracts/access/Ownable.sol";

//konfiguracja wszystkich waznych adresow, milton core, milton configuration, warren,
//milton admin,
contract MiltonAddressesManager is Ownable, IMiltonAddressesManager {

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant WARREN = 'WARREN';
    bytes32 private constant MILTON = 'MILTON';
    bytes32 private constant MILTON_CONFIGURATION = 'MILTON_CONFIGURATION';


    function setAddressAsProxy(bytes32 id, address implementationAddress)
    external
    override
    onlyOwner
    {
        _updateImpl(id, implementationAddress);
        emit AddressSet(id, implementationAddress, true);
    }

    function setAddress(bytes32 id, address newAddress) external override onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    function getAddress(bytes32 id) public view override returns (address) {
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

    //TODO: verify it, inspired by Aave
    function _updateImpl(bytes32 id, address newAddress) internal {
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