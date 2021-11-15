// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IIporConfiguration {

    event MiltonAddressUpdated(address indexed newAddress);
    event MiltonStorageAddressUpdated(address indexed newAddress);
    event MiltonUtilizationStrategyUpdated(address indexed newAddress);
    event MiltonSpreadStrategyUpdated(address indexed newAddress);
    event WarrenAddressUpdated(address indexed newAddress);
    event WarrenStorageAddressUpdated(address indexed newAddress);
    event IporAssetConfigurationAddressUpdated(address indexed asset, address indexed newAddress);
    event ProxyCreated(string id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event AssetAddressRemoved(address indexed asset);
    event AssetAddressAdd(address newAddress);
    event JosephAddressUpdated(address indexed newJosephAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getPublicationFeeTransferer() external view returns (address);

    function setPublicationFeeTransferer(address publicationFeeTransferer) external;

    function getMilton() external view returns (address);

    function setMilton(address milton) external;

    function getMiltonStorage() external view returns (address);

    function setMiltonStorage(address miltonStorage) external;

    function getMiltonUtilizationStrategy() external view returns (address);

    function setMiltonUtilizationStrategy(address miltonUtilizationStrategy) external;

    function getMiltonSpreadStrategy() external view returns (address);

    function setMiltonSpreadStrategy(address miltonSpreadStrategy) external;

    function getIporAssetConfiguration(address asset) external view returns (address);

    function setIporAssetConfiguration(address asset, address iporConfig) external;

    function getWarren() external view returns (address);

    function setWarren(address warren) external;

    function setWarrenStorage(address warrenStorage) external;

    function getWarrenStorage() external view returns (address);

    function getAssets() external view returns (address[] memory);

    function addAsset(address asset) external;

    function assetSupported(address asset) external view returns (uint256);

    function removeAsset(address asset) external;

    function getJoseph() external view returns (address);

    function setJoseph(address joseph) external;


}
