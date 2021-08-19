// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IMiltonAddressesManager {

    event MiltonAddressUpdated(address indexed newAddress);
    event WarrenAddressUpdated(address indexed newAddress);
    event MiltonConfigurationAddressUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getMilton() external view returns (address);

    function setMiltonImpl(address miltonImpl) external;

    function getMiltonConfiguration() external view returns (address);

    function setMiltonConfigurationImpl(address miltonConfigImpl) external;

    function getWarren() external view returns (address);

    function setWarrenImpl(address warrenImpl) external;
}