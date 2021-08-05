// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import {Errors} from '../Errors.sol';
import './IporOracleStorage.sol';
import "../interfaces/IIporOracle.sol";
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Constants} from '../libraries/Constants.sol';

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract IporOracle is IporOracleV1Storage, IIporOracle {

    /// @notice event emitted when IPOR Index is updated by Updater
    event IporIndexUpdate(string asset, uint256 indexValue, uint256 ibtPrice, uint256 date);

    /// @notice event emitted when IPOR Index Updater is added by Admin
    event IporIndexUpdaterAdd(address _updater);

    /// @notice event emitted when IPOR Index Updater is removed by Admin
    event IporIndexUpdaterRemove(address _updater);

    event Log(uint256 message);

    constructor() {
        admin = msg.sender;
    }

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
                indexes[assets[i]].ibtPrice,
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

    function _updateIndex(string memory _asset, uint256 _indexValue, uint256 updateTimestamp) internal onlyUpdater {
        bool assetExists = false;
        bytes32 _assetHash = keccak256(abi.encodePacked(_asset));

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == _assetHash) {
                assetExists = true;
            }
        }

        uint256 _ibtNewPrice;

        if (assetExists == false) {
            assets.push(_assetHash);
            _ibtNewPrice = 1e20;
        } else {
            _ibtNewPrice = _accrueInterestBearingTokenPrice(indexes[_assetHash], updateTimestamp);
        }

        indexes[_assetHash] = DataTypes.IPOR(_asset, _indexValue, _ibtNewPrice, updateTimestamp);

        emit IporIndexUpdate(_asset, _indexValue, _ibtNewPrice, updateTimestamp);
    }

    /**
     * @notice Return IPOR index for specific asset
     * @param _asset The asset symbol
     * @return indexValue then value of IPOR Index for particular asset
     * @return ibtPrice interest bearing token in this particular moment
     * @return blockTimestamp date when IPOR Index was calculated for asset
     *
     */
    function getIndex(string memory _asset) external view override(IIporOracle)
    returns (uint256 indexValue, uint256 ibtPrice, uint256 blockTimestamp) {
        bytes32 _assetHash = keccak256(abi.encodePacked(_asset));
        DataTypes.IPOR storage _iporIndex = indexes[_assetHash];
        return (
        indexValue = _iporIndex.indexValue,
        ibtPrice = _iporIndex.ibtPrice,
        blockTimestamp = _iporIndex.blockTimestamp
        );
    }



    /**
     * @notice Add updater address to list of updaters who are authorized to actualize IPOR Index in Oracle
     * @param _updater Address of new updater
     *
     */
    function addUpdater(address _updater) public onlyAdmin {
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
    function removeUpdater(address _updater) public onlyAdmin {

        for (uint256 i; i < updaters.length; i++) {
            if (updaters[i] == _updater) {
                delete updaters[i];
                emit IporIndexUpdaterRemove(_updater);
            }
        }
    }

    /**
    * @notice Mathematical formula which accrue actual Interest Bearing Token Price based on currently valid IPOR Index and current block timestamp
    * @param _lastIPOR last IPOR Index stored in blockchain
    * @param _currentBlockTimestamp current block timestamp
    */
    function _accrueInterestBearingTokenPrice(DataTypes.IPOR memory _lastIPOR, uint256 _currentBlockTimestamp) internal pure returns (uint256){
        return _lastIPOR.ibtPrice * (Constants.MILTON_DECIMALS_FACTOR
        + (_lastIPOR.indexValue * ((_currentBlockTimestamp - _lastIPOR.blockTimestamp) * Constants.MILTON_DECIMALS_FACTOR))
        / Constants.YEAR_IN_SECONDS_WITH_FACTOR) / Constants.MILTON_DECIMALS_FACTOR;
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

    /**
     * @notice Modifier which checks if caller is admin for this contract
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, Errors.CALLER_NOT_IPOR_ORACLE_ADMIN);
        _;
    }

}