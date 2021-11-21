// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IIporAddressesManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from '../Errors.sol';
import "./AccessControlConfiguration.sol";

contract IporAddressesManager is AccessControlConfiguration(msg.sender), Ownable, IIporAddressesManager {

    //@notice list of supported assets in IPOR Protocol example: DAI, USDT, USDC
    address [] public assets;

    //@notice value - flag 1 - is supported, 0 - is not supported
    mapping(address => uint256) public supportedAssets;

    //@notice mapping underlying asset address to IPOR Liquidity Pool Token addresses
    mapping(address => address) public ipTokens;

    //@notice mapping underlying asset address to ipor configuration address
    mapping(address => address) public iporConfigurations;

    //@notice mapping underlying asset address to Asset Management Vault
    mapping(address => address) public assetManagementVaults;


    mapping(bytes32 => address) private _addresses;

    //this treasurer manage ipor publication fee balance, key is an asset
    mapping(address => address) charlieTreasurers;

    //this treasurer manage opening fee balance, key is an asset
    mapping(address => address) treasureTreasurers;

    //@notice the user who can transfer publication fee to Charlie Treasurer
    bytes32 private constant PUBLICATION_FEE_TRANSFERER = keccak256("PUBLICATION_FEE_TRANSFERER");
    bytes32 private constant WARREN = keccak256("WARREN");
    bytes32 private constant WARREN_STORAGE = keccak256("WARREN_STORAGE");
    bytes32 private constant MILTON = keccak256("MILTON");
    bytes32 private constant MILTON_STORAGE = keccak256("MILTON_STORAGE");
    bytes32 private constant MILTON_UTILIZATION_STRATEGY = keccak256("MILTON_UTILIZATION_STRATEGY");
    bytes32 private constant MILTON_SPREAD_STRATEGY = keccak256("MILTON_SPREAD_STRATEGY");
    bytes32 private constant JOSEPH = keccak256("JOSEPH");

    function setAddress(bytes32 id, address newAddress) external override onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    function getAddress(bytes32 id) external view override returns (address) {
        return _addresses[id];
    }

    function getPublicationFeeTransferer() external view override returns (address) {
        return _addresses[PUBLICATION_FEE_TRANSFERER];
    }

    function setPublicationFeeTransferer(address publicationFeeTransferer) external override {
        _addresses[PUBLICATION_FEE_TRANSFERER] = publicationFeeTransferer;
        emit AddressSet(PUBLICATION_FEE_TRANSFERER, publicationFeeTransferer, false);
    }

    function getMilton() external view override returns (address) {
        return _addresses[MILTON];
    }

    function setMiltonImpl(address miltonImpl) external override onlyRole(MILTON_ROLE) {
        _addresses[MILTON] = miltonImpl;
        emit MiltonAddressUpdated(miltonImpl);
    }

    function getMiltonStorage() external view override returns (address) {
        return _addresses[MILTON_STORAGE];
    }

    function setMiltonStorageImpl(address miltonStorageImpl) external override onlyRole(MILTON_STORAGE_ROLE) {
        _addresses[MILTON_STORAGE] = miltonStorageImpl;
        emit MiltonStorageAddressUpdated(miltonStorageImpl);
    }

    function getMiltonUtilizationStrategy() external view override returns (address) {
        return _addresses[MILTON_UTILIZATION_STRATEGY];
    }

    function setMiltonUtilizationStrategyImpl(address miltonUtilizationStrategyImpl) external override onlyRole(MILTON_UTILIZATION_STRATEGY_ROLE) {
        _addresses[MILTON_UTILIZATION_STRATEGY] = miltonUtilizationStrategyImpl;
        emit MiltonUtilizationStrategyUpdated(miltonUtilizationStrategyImpl);
    }

    function getMiltonSpreadStrategy() external view override returns (address) {
        return _addresses[MILTON_SPREAD_STRATEGY];
    }

    function setMiltonSpreadStrategyImpl(address miltonSpreadStrategyImpl) external override onlyRole(MILTON_SPREAD_STRATEGY_ROLE) {
        _addresses[MILTON_SPREAD_STRATEGY] = miltonSpreadStrategyImpl;
        emit MiltonSpreadStrategyUpdated(miltonSpreadStrategyImpl);
    }

    function getIporConfiguration(address asset) external view override returns (address) {
        return iporConfigurations[asset];
    }

    function setIporConfiguration(address asset, address iporConfigImpl) external override onlyRole(IPOR_CONFIGURATION_ROLE) {
        require(supportedAssets[asset] == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);
        iporConfigurations[asset] = iporConfigImpl;
        emit IporConfigurationAddressUpdated(asset, iporConfigImpl);
    }

    function getWarren() external view override returns (address) {
        return _addresses[WARREN];
    }

    function setWarrenImpl(address warrenImpl) external override onlyRole(WARREN_ROLE) {
        _addresses[WARREN] = warrenImpl;
        emit WarrenAddressUpdated(warrenImpl);
    }


    function getCharlieTreasurer(address asset) external override view returns (address) {
        return charlieTreasurers[asset];
    }

    function setCharlieTreasurer(address asset, address charlieTreasurer) external override onlyRole(CHARLIE_TREASURER_ROLE) {
        require(supportedAssets[asset] == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);
        charlieTreasurers[asset] = charlieTreasurer;
        emit CharlieTreasurerUpdated(asset, charlieTreasurer);
    }

    function getTreasureTreasurer(address asset) external override view returns (address) {
        return treasureTreasurers[asset];
    }

    function setTreasureTreasurer(address asset, address treasureTreasurer) external override onlyRole(TREASURE_TREASURER_ROLE) {
        require(supportedAssets[asset] == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);
        treasureTreasurers[asset] = treasureTreasurer;
        emit TreasureTreasurerUpdated(asset, treasureTreasurer);
    }

    function getAssets() external override view returns (address[] memory){
        return assets;
    }

    function addAsset(address asset) external override onlyRole(IPOR_ASSETS_ROLE) {
        require(asset != address(0), Errors.WRONG_ADDRESS);
        bool assetExists = false;
        for (uint256 i; i < assets.length; i++) {
            if (assets[i] == asset) {
                assetExists = true;
            }
        }
        if (assetExists == false) {
            assets.push(asset);
            supportedAssets[asset] = 1;
            emit AssetAddressAdd(asset);
        }
    }

    function removeAsset(address asset) external override onlyRole(IPOR_ASSETS_ROLE) {
        require(asset != address(0), Errors.WRONG_ADDRESS);
        for (uint256 i; i < assets.length; i++) {
            if (assets[i] == asset) {
                delete assets[i];
                supportedAssets[asset] = 0;
                emit AssetAddressRemoved(asset);
                break;
            }
        }
    }

    function getIpToken(address asset) external override view returns (address){
        return ipTokens[asset];
    }

    function setIpToken(address asset, address ipTokenAddress) external override onlyOwner {
        require(supportedAssets[asset] == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);
        ipTokens[asset] = ipTokenAddress;
        emit IpTokenAddressUpdated(asset, ipTokenAddress);
    }

    function getJoseph() external override view returns (address){
        return _addresses[JOSEPH];
    }

    function setJoseph(address newJoseph) external override onlyOwner {
        _addresses[JOSEPH] = newJoseph;
        emit JosephAddressUpdated(newJoseph);
    }

    function getAssetManagementVault(address asset) external override view returns (address){
        return assetManagementVaults[asset];
    }

    function setAssetManagementVault(address asset, address newAssetManagementVaultAddress) external override onlyOwner {
        require(supportedAssets[asset] == 1, Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED);
        assetManagementVaults[asset] = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(asset, newAssetManagementVaultAddress);
    }

    function assetSupported(address asset) external override view returns (uint256) {
        return supportedAssets[asset];
    }

    function setWarrenStorageImpl(address warrenStorageImpl) external override onlyOwner {
        _addresses[WARREN_STORAGE] = warrenStorageImpl;
        emit WarrenStorageAddressUpdated(warrenStorageImpl);
    }

    function getWarrenStorage() external override view returns (address) {
        return _addresses[WARREN_STORAGE];
    }
}
