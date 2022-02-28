// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IIporAssetConfiguration {
    //TODO: same order in interface and in implementation or remove if used immutable parameters
    event MiltonAddressUpdated(address indexed newAddress);
    event MiltonStorageAddressUpdated(address indexed newAddress);
    event JosephAddressUpdated(address indexed newJosephAddress);

    event AssetManagementVaultUpdated(
        address indexed asset,
        address indexed newAssetManagementVaultAddress
    );

    function getMilton() external view returns (address);

    function setMilton(address milton) external;

    function getMiltonStorage() external view returns (address);

    function setMiltonStorage(address miltonStorage) external;

    function getJoseph() external view returns (address);

    function setJoseph(address joseph) external;

    function getDecimals() external view returns (uint8);

    function getIpToken() external view returns (address);    

    function getAssetManagementVault() external view returns (address);

    function setAssetManagementVault(address newAssetManagementVaultAddress)
        external;
}
