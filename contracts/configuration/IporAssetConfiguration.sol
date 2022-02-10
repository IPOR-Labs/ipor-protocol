// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../libraries/types/DataTypes.sol";
import "../libraries/IporSwapLogic.sol";
import "../libraries/IporMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IporErrors} from "../IporErrors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "../amm/MiltonStorage.sol";
import "../interfaces/IMiltonEvents.sol";
import "../libraries/SoapIndicatorLogic.sol";

import "../interfaces/IIporAssetConfiguration.sol";
import "./AccessControlAssetConfiguration.sol";

//TODO: combine with Milton to minimize external calls in modifiers and simplify code
contract IporAssetConfiguration is
    UUPSUpgradeable,
    AccessControlAssetConfiguration,
    IIporAssetConfiguration
{
    using SafeCast for uint256;
    uint8 private _decimals;

    address private _asset;

    address private _ipToken;

    address private _milton;

    address private _miltonStorage;

    address private _joseph;

    address private _assetManagementVault;

    address private _charlieTreasurer;

    //TODO: fix this name; treasureManager
    address private _treasureTreasurer;

    function initialize(address asset, address ipToken) public initializer {
        _init();
        _asset = asset;
        _ipToken = ipToken;
        uint8 decimals = ERC20(asset).decimals();
        require(decimals != 0, IporErrors.CONFIG_ASSET_DECIMALS_TOO_LOW);
        _decimals = decimals;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(_ADMIN_ROLE)
    {}

    function getMilton() external view override returns (address) {
        return _milton;
    }

    function setMilton(address milton)
        external
        override
        onlyRole(_MILTON_ROLE)
    {
        _milton = milton;
        emit MiltonAddressUpdated(milton);
    }

    function getMiltonStorage() external view override returns (address) {
        return _miltonStorage;
    }

    function setMiltonStorage(address miltonStorage)
        external
        override
        onlyRole(_MILTON_STORAGE_ROLE)
    {
        _miltonStorage = miltonStorage;
        emit MiltonStorageAddressUpdated(miltonStorage);
    }

    function getJoseph() external view override returns (address) {
        return _joseph;
    }

    function setJoseph(address joseph)
        external
        override
        onlyRole(_JOSEPH_ROLE)
    {
        _joseph = joseph;
        emit JosephAddressUpdated(joseph);
    }

    function getDecimals() external view override returns (uint8) {
        return _decimals;
    }

    function getCharlieTreasurer() external view override returns (address) {
        return _charlieTreasurer;
    }

    function setCharlieTreasurer(address newCharlieTreasurer)
        external
        override
        onlyRole(_CHARLIE_TREASURER_ROLE)
    {
        require(newCharlieTreasurer != address(0), IporErrors.WRONG_ADDRESS);
        _charlieTreasurer = newCharlieTreasurer;
        emit CharlieTreasurerUpdated(_asset, newCharlieTreasurer);
    }

    function getTreasureTreasurer() external view override returns (address) {
        return _treasureTreasurer;
    }

    function setTreasureTreasurer(address newTreasureTreasurer)
        external
        override
        onlyRole(_TREASURE_TREASURER_ROLE)
    {
        require(newTreasureTreasurer != address(0), IporErrors.WRONG_ADDRESS);
        _treasureTreasurer = newTreasureTreasurer;
        emit TreasureTreasurerUpdated(_asset, newTreasureTreasurer);
    }

    function getIpToken() external view override returns (address) {
        return _ipToken;
    }

    function getAssetManagementVault()
        external
        view
        override
        returns (address)
    {
        return _assetManagementVault;
    }

    function setAssetManagementVault(address newAssetManagementVaultAddress)
        external
        override
        onlyRole(_ASSET_MANAGEMENT_VAULT_ROLE)
    {
        require(
            newAssetManagementVaultAddress != address(0),
            IporErrors.WRONG_ADDRESS
        );
        _assetManagementVault = newAssetManagementVaultAddress;
        emit AssetManagementVaultUpdated(
            _asset,
            newAssetManagementVaultAddress
        );
    }
}
