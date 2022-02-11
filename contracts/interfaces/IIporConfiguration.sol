// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporConfiguration {    
    event MiltonUtilizationStrategyUpdated(address indexed newAddress);    
    event MiltonPublicationFeeTransfererUpdated(address indexed newAddress);        
    event IporAssetConfigurationAddressUpdated(
        address indexed asset,
        address indexed newAddress
    );
    
    event AssetAddressRemoved(address indexed asset);
    event AssetAddressAdd(address newAddress);    

    function getMiltonPublicationFeeTransferer()
        external
        view
        returns (address);

    function setMiltonPublicationFeeTransferer(address publicationFeeTransferer)
        external;    
    
    function getIporAssetConfiguration(address asset)
        external
        view
        returns (address);

    function setIporAssetConfiguration(address asset, address iporConfig)
        external;

    function getWarren() external view returns (address);

}
