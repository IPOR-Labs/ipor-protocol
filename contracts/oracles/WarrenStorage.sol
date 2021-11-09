// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarrenStorage.sol";
import {Constants} from '../libraries/Constants.sol';
import {Errors} from '../Errors.sol';
import "../libraries/IporLogic.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAddressesManager.sol";

/**
 * @title Ipor Oracle Storage initial version
 * @author IPOR Labs
 */
contract WarrenStorage is Ownable, IWarrenStorage {

    using IporLogic for DataTypes.IPOR;

    /// @notice event emitted when IPOR Index is updated by Updater
    event IporIndexUpdate(address asset, uint256 indexValue, uint256 quasiIbtPrice, uint256 date);

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexUpdaterAdd(address updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexUpdaterRemove(address updater);

    /// @notice list of IPOR indexes for particular assets
    mapping(address => DataTypes.IPOR) public indexes;

    /// @notice list of assets used in indexes mapping
    address[] public assets;

    /// @notice list of addresses which has rights to modify indexes mapping
    address[] public updaters;

    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    function getAssets() external override view returns (address[] memory) {
        return assets;
    }

    function getIndex(address asset) external override view returns (DataTypes.IPOR memory) {
        return indexes[asset];
    }

    function updateIndexes(address[] memory _assets, uint256[] memory indexValues, uint256 updateTimestamp) external override onlyUpdater {
        require(_assets.length == indexValues.length, Errors.WARREN_INPUT_ARRAYS_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _assets.length; i++) {
            IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(_assets[i]));
            _updateIndex(_assets[i], indexValues[i], updateTimestamp, iporConfiguration.getMultiplicator());
        }
    }

    function addUpdater(address updater) external override onlyOwner {
        _addUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        require(updater != address(0), Errors.WARREN_WRONG_UPDATER_ADDRESS);
        for (uint256 i; i < updaters.length; i++) {
            if (updaters[i] == updater) {
                delete updaters[i];
                emit IporIndexUpdaterRemove(updater);
            }
        }
    }

    function getUpdaters() external override view returns (address[] memory) {
        return updaters;
    }

    function _addUpdater(address updater) internal {
        require(updater != address(0), Errors.WARREN_WRONG_UPDATER_ADDRESS);
        bool updaterExists = false;
        for (uint256 i; i < updaters.length; i++) {
            if (updaters[i] == updater) {
                updaterExists = true;
            }
        }
        if (updaterExists == false) {
            updaters.push(updater);
            emit IporIndexUpdaterAdd(updater);
        }
    }

    function _updateIndex(address asset, uint256 indexValue, uint256 updateTimestamp, uint256 multiplicator) internal onlyUpdater {

        bool assetExists = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == asset) {
                assetExists = true;
            }
        }

        uint256 newQuasiIbtPrice;

        if (assetExists == false) {
            //TODO: consider asset support configured in IporAddressesManager
            assets.push(asset);
            newQuasiIbtPrice = multiplicator * Constants.YEAR_IN_SECONDS;
        } else {
            newQuasiIbtPrice = indexes[asset].accrueQuasiIbtPrice(updateTimestamp);
        }
        indexes[asset] = DataTypes.IPOR(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
        emit IporIndexUpdate(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
    }

    modifier onlyUpdater() {
        bool allowed = false;
        address[] memory _updaters = updaters;
        for (uint256 i = 0; i < _updaters.length; i++) {
            if (_updaters[i] == msg.sender) {
                allowed = true;
                break;
            }
        }
        require(allowed == true, Errors.WARREN_CALLER_NOT_WARREN_UPDATER);
        _;
    }

}
