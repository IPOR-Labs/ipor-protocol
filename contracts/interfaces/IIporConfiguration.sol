// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporConfiguration {    
    event MiltonUtilizationStrategyUpdated(address indexed newAddress);
    event MiltonSpreadModelUpdated(address indexed newAddress);
    event MiltonPublicationFeeTransfererUpdated(address indexed newAddress);
    event WarrenAddressUpdated(address indexed newAddress);
    event WarrenStorageAddressUpdated(address indexed newAddress);
    event IporAssetConfigurationAddressUpdated(
        address indexed asset,
        address indexed newAddress
    );
    event ProxyCreated(string id, address indexed newAddress);
    event AssetAddressRemoved(address indexed asset);
    event AssetAddressAdd(address newAddress);    

    function getMiltonPublicationFeeTransferer()
        external
        view
        returns (address);

    function setMiltonPublicationFeeTransferer(address publicationFeeTransferer)
        external;    

    function getMiltonLPUtilizationStrategy() external view returns (address);

    function setMiltonLPUtilizationStrategy(address miltonUtilizationStrategy)
        external;

    function getMiltonSpreadModel() external view returns (address);

    function setMiltonSpreadModel(address miltonSpreadModel) external;

    function getIporAssetConfiguration(address asset)
        external
        view
        returns (address);

    function setIporAssetConfiguration(address asset, address iporConfig)
        external;

    function getWarren() external view returns (address);

    function setWarren(address warren) external;

    function setWarrenStorage(address warrenStorage) external;

    function getWarrenStorage() external view returns (address);

    function getAssets() external view returns (address[] memory);

    function addAsset(address asset) external;

    function assetSupported(address asset) external view returns (uint256);

    function removeAsset(address asset) external;

}
