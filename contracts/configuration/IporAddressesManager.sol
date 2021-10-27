// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../interfaces/IIporAddressesManager.sol";
//TODO: clarify if better is to have external libraries in local folder
import "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from '../Errors.sol';

contract IporAddressesManager is Ownable, IIporAddressesManager {

    //@notice list of supported assets in IPOR Protocol example: DAI, USDT, USDC
    address [] public assets;

    //@notice value - flag 1 - is supported, 0 - is not supported
    mapping(address => uint256) public supportedAssets;

    //@notice mapping underlying asset address to ipor token address
    mapping(address => address) public iporTokens;

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
    bytes32 private constant IPOR_CONFIGURATION = keccak256("IPOR_CONFIGURATION");
    bytes32 private constant JOSEPH = keccak256("JOSEPH");


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

    function getPublicationFeeTransferer() external view override returns (address) {
        return getAddress(PUBLICATION_FEE_TRANSFERER);
    }

    function setPublicationFeeTransferer(address publicationFeeTransferer) external override {
        _addresses[PUBLICATION_FEE_TRANSFERER] = publicationFeeTransferer;
        emit AddressSet(PUBLICATION_FEE_TRANSFERER, publicationFeeTransferer, false);
    }

    function getMilton() external view override returns (address) {
        return getAddress(MILTON);
    }

    //TODO: implement _updateImpl and then use this method
    function setMiltonImpl(address miltonImpl) external override onlyOwner {
        _updateImpl(MILTON, miltonImpl);
        emit MiltonAddressUpdated(miltonImpl);
    }

    function getMiltonStorage() external view override returns (address) {
        return getAddress(MILTON_STORAGE);
    }

    function setMiltonStorageImpl(address miltonStorageImpl) external override onlyOwner {
        _updateImpl(MILTON_STORAGE, miltonStorageImpl);
        emit MiltonStorageAddressUpdated(miltonStorageImpl);
    }

    function getMiltonUtilizationStrategy() external view override returns (address) {
        return getAddress(MILTON_UTILIZATION_STRATEGY);
    }

    function setMiltonUtilizationStrategyImpl(address miltonUtilizationStrategyImpl) external override onlyOwner {
        _updateImpl(MILTON_UTILIZATION_STRATEGY, miltonUtilizationStrategyImpl);
        emit MiltonUtilizationStrategyUpdated(miltonUtilizationStrategyImpl);
    }

    function getMiltonSpreadStrategy() external view override returns (address) {
        return getAddress(MILTON_SPREAD_STRATEGY);
    }

    function setMiltonSpreadStrategyImpl(address miltonSpreadStrategyImpl) external override onlyOwner {
        _updateImpl(MILTON_SPREAD_STRATEGY, miltonSpreadStrategyImpl);
        emit MiltonSpreadStrategyUpdated(miltonSpreadStrategyImpl);
    }

    function getIporConfiguration() external view override returns (address) {
        return getAddress(IPOR_CONFIGURATION);
    }

    //TODO: implement _updateImpl and then use this method
    function setIporConfigurationImpl(address iporConfigImpl) external override onlyOwner {
        _updateImpl(IPOR_CONFIGURATION, iporConfigImpl);
        emit IporConfigurationAddressUpdated(iporConfigImpl);
    }

    function getWarren() external view override returns (address) {
        return getAddress(WARREN);
    }

    //TODO: implement _updateImpl and then use this method
    function setWarrenImpl(address warrenImpl) external override onlyOwner {
        _updateImpl(WARREN, warrenImpl);
        emit WarrenAddressUpdated(warrenImpl);
    }


    function getCharlieTreasurer(address asset) external override view returns (address) {
        return charlieTreasurers[asset];
    }

    function setCharlieTreasurer(address asset, address _charlieTreasurer) external override onlyOwner {
        charlieTreasurers[asset] = _charlieTreasurer;
        emit CharlieTreasurerUpdated(asset, _charlieTreasurer);
    }

    function getTreasureTreasurer(address asset) external override view returns (address) {
        return treasureTreasurers[asset];
    }

    function setTreasureTreasurer(address asset, address _treasureTreasurer) external override onlyOwner {
        treasureTreasurers[asset] = _treasureTreasurer;
        emit TreasureTreasurerUpdated(asset, _treasureTreasurer);
    }

    function getAssets() external override view returns (address[] memory){
        return assets;
    }

    function addAsset(address asset) external override onlyOwner {
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

    function removeAsset(address asset) external override onlyOwner {
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

    function getIporToken(address unserlyingAsset) external override view returns (address){
        return iporTokens[unserlyingAsset];
    }

    function setIporToken(address underlyingAssetAddress, address iporTokenAddress) external override onlyOwner {
        iporTokens[underlyingAssetAddress] = iporTokenAddress;
        emit IporTokenAddressUpdated(underlyingAssetAddress, iporTokenAddress);
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
        assetManagementVaults[asset] = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(asset, newAssetManagementVaultAddress);
    }

    function assetSupported(address asset) external override view returns (uint256) {
        return supportedAssets[asset];
    }

    function setWarrenStorageImpl(address warrenStorageImpl) external override onlyOwner {
        _updateImpl(WARREN_STORAGE, warrenStorageImpl);
        emit WarrenStorageAddressUpdated(warrenStorageImpl);
    }

    function getWarrenStorage() external override view returns (address) {
        return getAddress(WARREN_STORAGE);
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
