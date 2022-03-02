// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporConfiguration {
    event IporAssetConfigurationAddressUpdated(
        address indexed asset,
        address indexed newAddress
    );

    event AssetAddressRemoved(address indexed asset);
    event AssetAddressAdd(address newAddress);

    function getIporAssetConfiguration(address asset)
        external
        view
        returns (address);

    function setIporAssetConfiguration(address asset, address iporConfig)
        external;
}
