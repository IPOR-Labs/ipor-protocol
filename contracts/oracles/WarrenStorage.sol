// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IWarrenStorage.sol";
import {Constants} from '../libraries/Constants.sol';
import {Errors} from '../Errors.sol';
import "../libraries/IporLogic.sol";

/**
 * @title Ipor Oracle Storage initial version
 * @author IPOR Labs
 */
contract WarrenStorage is Ownable, IWarrenStorage {

    using IporLogic for DataTypes.IPOR;

    /// @notice event emitted when IPOR Index is updated by Updater
    event IporIndexUpdate(string asset, uint256 indexValue, uint256 quasiIbtPrice, uint256 date);

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexUpdaterAdd(address _updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexUpdaterRemove(address _updater);

    /// @notice list of IPOR indexes for particular assets
    mapping(bytes32 => DataTypes.IPOR) public indexes;

    /// @notice list of assets used in indexes mapping
    bytes32[] public assets;

    /// @notice list of addresses which has rights to modify indexes mapping
    address[] public updaters;

    function getAssets() external override view returns (bytes32[] memory) {
        return assets;
    }

    function getIndex(bytes32 asset) external override view returns (DataTypes.IPOR memory) {
        return indexes[asset];
    }

    function updateIndexes(string[] memory _assets, uint256[] memory _indexValues, uint256 updateTimestamp) external override onlyUpdater {
        require(_assets.length == _indexValues.length, Errors.IPOR_ORACLE_INPUT_ARRAYS_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _assets.length; i++) {
            _updateIndex(_assets[i], _indexValues[i], updateTimestamp);
        }
    }

    function addUpdater(address updater) external override onlyOwner {
        _addUpdater(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
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

    function _updateIndex(string memory asset, uint256 indexValue, uint256 updateTimestamp) internal onlyUpdater {

        bool assetExists = false;
        bytes32 assetHash = keccak256(abi.encodePacked(asset));
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == assetHash) {
                assetExists = true;
            }
        }

        uint256 newQuasiIbtPrice;

        if (assetExists == false) {
            assets.push(assetHash);
            newQuasiIbtPrice = Constants.MD_YEAR_IN_SECONDS;
        } else {
            newQuasiIbtPrice = indexes[assetHash].accrueQuasiIbtPrice(updateTimestamp);
        }
        indexes[assetHash] = DataTypes.IPOR(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
        emit IporIndexUpdate(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
    }

    modifier onlyUpdater() {
        bool allowed = false;
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == msg.sender) {
                allowed = true;
                break;
            }
        }
        require(allowed == true, Errors.CALLER_NOT_WARREN_UPDATER);
        _;
    }

}
