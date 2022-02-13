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
    address internal _warren;

    //@notice mapping underlying asset address to ipor configuration address
    mapping(address => address) public iporAssetConfigurations;

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant _MILTON_PUBLICATION_FEE_TRANSFERER =
        keccak256("MILTON_PUBLICATION_FEE_TRANSFERER");

    function initialize() public initializer {
        _init();        
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(_ADMIN_ROLE)
    {}

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
        iporAssetConfigurations[asset] = iporConfig;
        emit IporAssetConfigurationAddressUpdated(asset, iporConfig);
    }
}
