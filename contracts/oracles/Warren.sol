// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from '../Errors.sol';
import './WarrenStorage.sol';
import "../interfaces/IWarren.sol";
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Constants} from '../libraries/Constants.sol';
import "../libraries/IporLogic.sol";
import {AmmMath} from '../libraries/AmmMath.sol';

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract Warren is Ownable, WarrenV1Storage, IWarren {

    using IporLogic for DataTypes.IPOR;

    /// @notice event emitted when IPOR Index is updated by Updater
    event IporIndexUpdate(string asset, uint256 indexValue, uint256 ibtPrice, uint256 date);

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexUpdaterAdd(address _updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexUpdaterRemove(address _updater);

    /**
     * @notice Returns IPOR Index value for all assets supported by IPOR Oracle
     * @return List of assets with calculated IPOR Index in current moment.
     *
     */
    function getIndexes() external view returns (DataTypes.IPOR[] memory) {
        DataTypes.IPOR[] memory _indexes = new DataTypes.IPOR[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            _indexes[i] = DataTypes.IPOR(
                indexes[assets[i]].asset,
                indexes[assets[i]].indexValue,
                AmmMath.division(indexes[assets[i]].quasiIbtPrice, Constants.YEAR_IN_SECONDS),
                indexes[assets[i]].blockTimestamp
            );
        }
        return _indexes;
    }

    function updateIndexes(string[] memory _assets, uint256[] memory _indexValues) public onlyUpdater {
        _updateIndexes(_assets, _indexValues, block.timestamp);
    }

    /**
     * @notice Update IPOR index for specific asset
     * @param _asset The asset symbol
     * @param _indexValue The index value of IPOR for particular asset, Smart Contract assume that _indexValue has 18 decimals
     *
     */
    function updateIndex(string memory _asset, uint256 _indexValue) public onlyUpdater {
        _updateIndex(_asset, _indexValue, block.timestamp);

    }

    function _updateIndexes(string[] memory _assets, uint256[] memory _indexValues, uint256 updateTimestamp) internal onlyUpdater {
        require(_assets.length == _indexValues.length, Errors.IPOR_ORACLE_INPUT_ARRAYS_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _assets.length; i++) {
            _updateIndex(_assets[i], _indexValues[i], updateTimestamp);
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
            newQuasiIbtPrice = 1e18 * Constants.YEAR_IN_SECONDS;
        } else {
            newQuasiIbtPrice = indexes[assetHash].accrueIbtPrice(updateTimestamp);
        }

        indexes[assetHash] = DataTypes.IPOR(asset, indexValue, newQuasiIbtPrice, updateTimestamp);

        emit IporIndexUpdate(asset, indexValue, newQuasiIbtPrice, updateTimestamp);
    }

    /**
     * @notice Return IPOR index for specific asset
     * @param _asset The asset symbol
     * @return indexValue then value of IPOR Index for particular asset
     * @return ibtPrice interest bearing token in this particular moment
     * @return blockTimestamp date when IPOR Index was calculated for asset
     *
     */
    function getIndex(string memory _asset) external view override(IWarren)
    returns (uint256 indexValue, uint256 ibtPrice, uint256 blockTimestamp) {
        bytes32 _assetHash = keccak256(abi.encodePacked(_asset));
        DataTypes.IPOR storage _iporIndex = indexes[_assetHash];
        return (
        indexValue = _iporIndex.indexValue,
        ibtPrice = AmmMath.division(_iporIndex.quasiIbtPrice, Constants.YEAR_IN_SECONDS),
        blockTimestamp = _iporIndex.blockTimestamp
        );
    }

    /**
     * @notice Add updater address to list of updaters who are authorized to actualize IPOR Index in Oracle
     * @param _updater Address of new updater
     *
     */
    function addUpdater(address _updater) public onlyOwner {
        bool updaterExists = false;
        for (uint256 i; i < updaters.length; i++) {
            if (updaters[i] == _updater) {
                updaterExists = true;
            }
        }
        if (updaterExists == false) {
            updaters.push(_updater);
            emit IporIndexUpdaterAdd(_updater);
        }
    }

    /**
     * @notice Return list of updaters who are authorized to actualize IPOR Index in Oracle
     * @return list of updater addresses who are authorized to actualize IPOR Index in Oracle
     *
     */
    function getUpdaters() external view returns (address[] memory) {
        return updaters;
    }

    /**
     * @notice Remove specific address from list of IPOR Index authorized updaters
     * @param _updater address which will be removed from list of IPOR Index authorized updaters
     */
    function removeUpdater(address _updater) public onlyOwner {

        for (uint256 i; i < updaters.length; i++) {
            if (updaters[i] == _updater) {
                delete updaters[i];
                emit IporIndexUpdaterRemove(_updater);
            }
        }
    }

    /**
     * @notice Modifier which checks if caller is authorized to update IPOR Index
     */
    modifier onlyUpdater() {
        bool allowed = false;
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed == true, Errors.CALLER_NOT_IPOR_ORACLE_UPDATER);
        _;
    }
}