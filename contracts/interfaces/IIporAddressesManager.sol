// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IIporAddressesManager {

    event MiltonAddressUpdated(address indexed newAddress);
    event MiltonStorageAddressUpdated(address indexed newAddress);
    event MiltonUtilizationStrategyUpdated(address indexed newAddress);
    event MiltonSpreadStrategyUpdated(address indexed newAddress);
    event WarrenAddressUpdated(address indexed newAddress);
    event WarrenStorageAddressUpdated(address indexed newAddress);
    event IporConfigurationAddressUpdated(address indexed asset, address indexed newAddress);
    event CharlieTreasurerUpdated(address asset, address indexed newCharlieTreasurer);
    event TreasureTreasurerUpdated(address asset, address indexed newTreasureTreasurer);
    event ProxyCreated(string id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event AssetAddressRemoved(address indexed asset);
    event AssetAddressAdd(address newAddress);
    event IpTokenAddressUpdated(address indexed underlyingAssetAddress, address indexed newIpTokenAddress);
    event JosephAddressUpdated(address indexed newJosephAddress);
    event AssetManagementVaultUpdated(address indexed asset, address indexed newAssetManagementVaultAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function getPublicationFeeTransferer() external view returns (address);

    function setPublicationFeeTransferer(address publicationFeeTransferer) external;

    function getMilton() external view returns (address);

    function setMiltonImpl(address miltonImpl) external;

    function getMiltonStorage() external view returns (address);

    function setMiltonStorageImpl(address miltonStorageImpl) external;

    function getMiltonUtilizationStrategy() external view returns (address);

    function setMiltonUtilizationStrategyImpl(address miltonUtilizationStrategyImpl) external;

    function getMiltonSpreadStrategy() external view returns (address);

    function setMiltonSpreadStrategyImpl(address miltonSpreadStrategyImpl) external;

    function getIporConfiguration(address asset) external view returns (address);

    function setIporConfiguration(address asset, address iporConfigImpl) external;

    function getWarren() external view returns (address);

    function setWarrenImpl(address warrenImpl) external;

    function setWarrenStorageImpl(address warrenStorageImpl) external;

    function getWarrenStorage() external view returns (address);

    function getCharlieTreasurer(address asset) external view returns (address);

    function setCharlieTreasurer(address asset, address charlieTreasurer) external;

    function getTreasureTreasurer(address asset) external view returns (address);

    function setTreasureTreasurer(address asset, address treasureTreasurer) external;

    function getAssets() external view returns (address[] memory);

    function addAsset(address asset) external;

    function assetSupported(address asset) external view returns (uint256);

    function removeAsset(address asset) external;

    function getIpToken(address unserlyingAsset) external view returns (address);

    function setIpToken(address underlyingAsset, address ipToken) external;

    function getJoseph() external view returns (address);

    function setJoseph(address newJoseph) external;

    function getAssetManagementVault(address asset) external view returns (address);

    function setAssetManagementVault(address asset, address newAssetManagementVaultAddress) external;

}
