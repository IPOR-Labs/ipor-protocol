// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IIporAddressesManager {

    event MiltonAddressUpdated(address indexed newAddress);
    event MiltonStorageAddressUpdated(address indexed newAddress);
    event WarrenAddressUpdated(address indexed newAddress);
    event MiltonConfigurationAddressUpdated(address indexed newAddress);
    event CharlieTreasurerUpdated(string asset, address indexed newCharlieTreasurer);
    event TreasureTreasurerUpdated(string asset, address indexed newTreasureTreasurer);
    event ProxyCreated(string id, address indexed newAddress);
    event AddressSet(string id, address indexed newAddress, bool hasProxy);

    function setAddress(string memory id, address newAddress) external;

    function setAddressAsProxy(string memory id, address impl) external;

    function getAddress(string memory id) external view returns (address);

    function getMilton() external view returns (address);

    function setMiltonImpl(address miltonImpl) external;

    function getMiltonStorage() external view returns (address);

    function setMiltonStorageImpl(address miltonStorageImpl) external;

    function getMiltonConfiguration() external view returns (address);

    function setMiltonConfigurationImpl(address miltonConfigImpl) external;

    function getWarren() external view returns (address);

    function setWarrenImpl(address warrenImpl) external;

    function getCharlieTreasurer(string memory asset) external view returns (address);

    function setCharlieTreasurer(string memory asset, address _charlieTreasurer) external;

    function getTreasureTreasurer(string memory asset) external view returns (address);

    function setTreasureTreasurer(string memory asset, address _treasureTreasurer) external;
}