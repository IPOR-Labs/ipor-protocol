// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../interfaces/IIporConfiguration.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IporErrors} from "../IporErrors.sol";
import "./AccessControlConfiguration.sol";

contract IporConfiguration is
    UUPSUpgradeable,
    AccessControlConfiguration,
    IIporConfiguration
{
    //@notice list of supported assets in IPOR Protocol example: DAI, USDT, USDC
    address[] public assets;

    //@notice value - flag 1 - is supported, 0 - is not supported
    mapping(address => uint256) public supportedAssets;

    //@notice mapping underlying asset address to ipor configuration address
    mapping(address => address) public iporAssetConfigurations;

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant _WARREN = keccak256("WARREN");

    //TODO: move to MiltonConfiguration
    bytes32 private constant _MILTON_SPREAD_MODEL =
        keccak256("MILTON_SPREAD_MODEL");
    
    bytes32 private constant _MILTON_PUBLICATION_FEE_TRANSFERER =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER");

    function getWarren() external view override returns (address) {
        return _addresses[_WARREN];
    }

    function initialize() public initializer {
        _init();
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(_ADMIN_ROLE)
    {}

    function setWarren(address warren)
        external
        override
        onlyRole(_WARREN_ROLE)
    {
        _addresses[_WARREN] = warren;
        emit WarrenAddressUpdated(warren);
    }

    function getMiltonSpreadModel() external view override returns (address) {
        return _addresses[_MILTON_SPREAD_MODEL];
    }

    function setMiltonSpreadModel(address miltonSpreadModel)
        external
        override
        onlyRole(_MILTON_SPREAD_MODEL_ROLE)
    {
        _addresses[_MILTON_SPREAD_MODEL] = miltonSpreadModel;
        emit MiltonSpreadModelUpdated(miltonSpreadModel);
    }

    function getMiltonPublicationFeeTransferer()
        external
        view
        override
        returns (address)
    {
        return _addresses[_MILTON_PUBLICATION_FEE_TRANSFERER];
    }

    function setMiltonPublicationFeeTransferer(address publicationFeeTransferer)
        external
        override
        onlyRole(_MILTON_PUBLICATION_FEE_TRANSFERER_ROLE)
    {
        _addresses[
            _MILTON_PUBLICATION_FEE_TRANSFERER
        ] = publicationFeeTransferer;
        emit MiltonPublicationFeeTransfererUpdated(publicationFeeTransferer);
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
        onlyRole(_IPOR_ASSET_CONFIGURATION_ROLE)
    {
        require(
            supportedAssets[asset] == 1,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );
        iporAssetConfigurations[asset] = iporConfig;
        emit IporAssetConfigurationAddressUpdated(asset, iporConfig);
    }

    function getAssets() external view override returns (address[] memory) {
        return assets;
    }

    function addAsset(address asset)
        external
        override
        onlyRole(_IPOR_ASSETS_ROLE)
    {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        bool assetExists = false;
        uint256 i = 0;
        uint256 assetsLength = assets.length;
        for (i; i != assetsLength; i++) {
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
        onlyRole(_IPOR_ASSETS_ROLE)
    {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        uint256 i = 0;
        uint256 assetsLength = assets.length;
        for (i; i != assetsLength; i++) {
            if (assets[i] == asset) {
                delete assets[i];
                supportedAssets[asset] = 0;
                emit AssetAddressRemoved(asset);
                break;
            }
        }
    }

}
