// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from '../Errors.sol';
import "../interfaces/IWarren.sol";
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {Constants} from '../libraries/Constants.sol';
import "../libraries/IporLogic.sol";
import {AmmMath} from '../libraries/AmmMath.sol';
import "../interfaces/IWarrenStorage.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract Warren is Ownable, IWarren {

    using IporLogic for DataTypes.IPOR;

    IWarrenStorage warrenStorage;

    constructor(address warrenStorageAddr) {
        warrenStorage = IWarrenStorage(warrenStorageAddr);
    }

    function getIndex(string memory _asset) external view override
    returns (uint256 indexValue, uint256 ibtPrice, uint256 blockTimestamp) {
        bytes32 _assetHash = keccak256(abi.encodePacked(_asset));
        DataTypes.IPOR memory _iporIndex = warrenStorage.getIndex(_assetHash);
        return (
        indexValue = _iporIndex.indexValue,
        ibtPrice = AmmMath.division(_iporIndex.quasiIbtPrice, Constants.YEAR_IN_SECONDS),
        blockTimestamp = _iporIndex.blockTimestamp
        );
    }

    function getIndexes() external override view returns (DataTypes.IporFront[] memory) {
        bytes32[] memory assets = warrenStorage.getAssets();
        DataTypes.IporFront[] memory _indexes = new DataTypes.IporFront[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.IPOR memory iporIndex = warrenStorage.getIndex(assets[i]);
            _indexes[i] = DataTypes.IporFront(
                iporIndex.asset,
                iporIndex.indexValue,
                AmmMath.division(iporIndex.quasiIbtPrice, Constants.YEAR_IN_SECONDS),
                iporIndex.blockTimestamp
            );
        }
        return _indexes;
    }

    function updateIndex(string memory _asset, uint256 _indexValue) external override {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = _indexValue;
        string[] memory assets = new string[](1);
        assets[0] = _asset;
        warrenStorage.updateIndexes(assets, indexes, block.timestamp);
    }

    function updateIndexes(string[] memory _assets, uint256[] memory _indexValues) external override {
        warrenStorage.updateIndexes(_assets, _indexValues, block.timestamp);
    }

    function calculateAccruedIbtPrice(string memory asset, uint256 calculateTimestamp) external view override returns (uint256) {
        return AmmMath.division(warrenStorage.getIndex(keccak256(abi.encodePacked(asset)))
        .accrueQuasiIbtPrice(calculateTimestamp), Constants.YEAR_IN_SECONDS);
    }

    modifier onlyUpdater() {
        bool allowed = false;
        address[] memory updaters = warrenStorage.getUpdaters();
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == msg.sender) {
                allowed = true;
                break;
            }
        }
        require(allowed == true, Errors.WARREN_CALLER_NOT_WARREN_UPDATER);
        _;
    }

}