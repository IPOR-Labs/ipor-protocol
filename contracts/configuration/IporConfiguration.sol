// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/IIporConfiguration.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { Errors } from "../Errors.sol";
import "./AccessControlConfiguration.sol";

contract IporConfiguration is
    AccessControlConfiguration(msg.sender),
    IIporConfiguration
{
    //@notice list of supported assets in IPOR Protocol example: DAI, USDT, USDC
    address[] public assets;

    //@notice value - flag 1 - is supported, 0 - is not supported
    mapping(address => uint256) public supportedAssets;

    //@notice mapping underlying asset address to ipor configuration address
    mapping(address => address) public iporAssetConfigurations;

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant WARREN = keccak256("WARREN");
    bytes32 private constant WARREN_STORAGE = keccak256("WARREN_STORAGE");

    bytes32 private constant MILTON = keccak256("MILTON");
    bytes32 private constant MILTON_STORAGE = keccak256("MILTON_STORAGE");
    bytes32 private constant JOSEPH = keccak256("JOSEPH");

	//TODO: move to MiltonConfiguration
    bytes32 private constant MILTON_LP_UTILIZATION_STRATEGY =
        keccak256("MILTON_LP_UTILIZATION_STRATEGY");

	//TODO: move to MiltonConfiguration
    bytes32 private constant MILTON_SPREAD_STRATEGY =
        keccak256("MILTON_SPREAD_STRATEGY");
    bytes32 private constant MILTON_PUBLICATION_FEE_TRANSFERER =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER");

    function getMiltonPublicationFeeTransferer()
        external
        view
        override
        returns (address)
    {
        return _addresses[MILTON_PUBLICATION_FEE_TRANSFERER];
    }

    function setMiltonPublicationFeeTransferer(address publicationFeeTransferer)
        external
        override
        onlyRole(MILTON_PUBLICATION_FEE_TRANSFERER_ROLE)
    {
        _addresses[
            MILTON_PUBLICATION_FEE_TRANSFERER
        ] = publicationFeeTransferer;
        emit MiltonPublicationFeeTransfererUpdated(publicationFeeTransferer);
    }

    function getMilton() external view override returns (address) {
        return _addresses[MILTON];
    }

    function setMilton(address milton) external override onlyRole(MILTON_ROLE) {
        //TODO: when Milton address is changing make sure than allowance on Josepth is set to 0 for old milton
        _addresses[MILTON] = milton;
        emit MiltonAddressUpdated(milton);
    }

    function getMiltonStorage() external view override returns (address) {
        return _addresses[MILTON_STORAGE];
    }

    function setMiltonStorage(address miltonStorage)
        external
        override
        onlyRole(MILTON_STORAGE_ROLE)
    {
        _addresses[MILTON_STORAGE] = miltonStorage;
        emit MiltonStorageAddressUpdated(miltonStorage);
    }

    function getMiltonLPUtilizationStrategy()
        external
        view
        override
        returns (address)
    {
        return _addresses[MILTON_LP_UTILIZATION_STRATEGY];
    }

    function setMiltonLPUtilizationStrategy(address miltonUtilizationStrategy)
        external
        override
        onlyRole(MILTON_LP_UTILIZATION_STRATEGY_ROLE)
    {
        _addresses[MILTON_LP_UTILIZATION_STRATEGY] = miltonUtilizationStrategy;
        emit MiltonUtilizationStrategyUpdated(miltonUtilizationStrategy);
    }

    function getMiltonSpreadStrategy()
        external
        view
        override
        returns (address)
    {
        return _addresses[MILTON_SPREAD_STRATEGY];
    }

    function setMiltonSpreadStrategy(address miltonSpreadStrategy)
        external
        override
        onlyRole(MILTON_SPREAD_STRATEGY_ROLE)
    {
        _addresses[MILTON_SPREAD_STRATEGY] = miltonSpreadStrategy;
        emit MiltonSpreadStrategyUpdated(miltonSpreadStrategy);
    }

    function getIporAssetConfiguration(address asset)
        external
        view
        override
        returns (address)
    {
        return iporAssetConfigurations[asset];
    }

    function setIporAssetConfiguration(address asset, address iporConfig)
        external
        override
        onlyRole(IPOR_ASSET_CONFIGURATION_ROLE)
    {
        require(
            supportedAssets[asset] == 1,
            Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );
        iporAssetConfigurations[asset] = iporConfig;
        emit IporAssetConfigurationAddressUpdated(asset, iporConfig);
    }

    function getWarren() external view override returns (address) {
        return _addresses[WARREN];
    }

    function setWarren(address warren) external override onlyRole(WARREN_ROLE) {
        _addresses[WARREN] = warren;
        emit WarrenAddressUpdated(warren);
    }

    function getAssets() external view override returns (address[] memory) {
        return assets;
    }

    function addAsset(address asset)
        external
        override
        onlyRole(IPOR_ASSETS_ROLE)
    {
        require(asset != address(0), Errors.WRONG_ADDRESS);
        bool assetExists = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == asset) {
                assetExists = true;
            }
        }
        if (!assetExists) {
            assets.push(asset);
            supportedAssets[asset] = 1;
            emit AssetAddressAdd(asset);
        }
    }

    function removeAsset(address asset)
        external
        override
        onlyRole(IPOR_ASSETS_ROLE)
    {
        require(asset != address(0), Errors.WRONG_ADDRESS);
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == asset) {
                delete assets[i];
                supportedAssets[asset] = 0;
                emit AssetAddressRemoved(asset);
                break;
            }
        }
    }

    function getJoseph() external view override returns (address) {
        return _addresses[JOSEPH];
    }

    function setJoseph(address joseph) external override onlyRole(JOSEPH_ROLE) {
        _addresses[JOSEPH] = joseph;
        emit JosephAddressUpdated(joseph);
    }

    function assetSupported(address asset)
        external
        view
        override
        returns (uint256)
    {
        return supportedAssets[asset];
    }

    function setWarrenStorage(address warrenStorage)
        external
        override
        onlyRole(WARREN_STORAGE_ROLE)
    {
        _addresses[WARREN_STORAGE] = warrenStorage;
        emit WarrenStorageAddressUpdated(warrenStorage);
    }

    function getWarrenStorage() external view override returns (address) {
        return _addresses[WARREN_STORAGE];
    }
}
