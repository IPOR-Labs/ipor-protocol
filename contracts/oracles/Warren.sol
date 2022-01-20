// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IWarren.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Constants} from "../libraries/Constants.sol";
import "../libraries/IporLogic.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IWarrenStorage.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";

/**
 * @title IPOR Index Oracle Contract
 *
 * @author IPOR Labs
 */
contract Warren is Ownable, Pausable, IWarren {
    using IporLogic for DataTypes.IPOR;

    IIporConfiguration internal _iporConfiguration;

    constructor(address initialIporConfiguration) {
		require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
    }

    modifier onlyUpdater() {
        bool allowed = false;
        address[] memory updaters = IWarrenStorage(
            //TODO: avoid external call
            _iporConfiguration.getWarrenStorage()
        ).getUpdaters();
        for (uint256 i = 0; i < updaters.length; i++) {
            if (updaters[i] == msg.sender) {
                allowed = true;
                break;
            }
        }
        require(allowed, IporErrors.WARREN_CALLER_NOT_WARREN_UPDATER);
        _;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function getIndex(address asset)
        external
        view
        override
        returns (
            uint256 indexValue,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 blockTimestamp
        )
    {
        DataTypes.IPOR memory iporIndex = IWarrenStorage(
            _iporConfiguration.getWarrenStorage()
        ).getIndex(asset);
        return (
            indexValue = iporIndex.indexValue,
            ibtPrice = IporMath.division(
                iporIndex.quasiIbtPrice,
                Constants.YEAR_IN_SECONDS
            ),
            exponentialMovingAverage = iporIndex.exponentialMovingAverage,
            exponentialWeightedMovingVariance = iporIndex
                .exponentialWeightedMovingVariance,
            blockTimestamp = iporIndex.blockTimestamp
        );
    }

	function getAccruedIndex(uint256 calculateTimestamp, address asset) 

    //@notice indexValue value with number of decimals like in asset
    function updateIndex(address asset, uint256 indexValue)
        external
        override
        onlyUpdater
    {
        uint256[] memory indexes = new uint256[](1);
        indexes[0] = indexValue;
        address[] memory assets = new address[](1);
        assets[0] = asset;
        IWarrenStorage(_iporConfiguration.getWarrenStorage()).updateIndexes(
            assets,
            indexes,
            block.timestamp
        );
    }

    function updateIndexes(
        address[] memory assets,
        uint256[] memory indexValues
    ) external override onlyUpdater {
        IWarrenStorage(_iporConfiguration.getWarrenStorage()).updateIndexes(
            assets,
            indexValues,
            block.timestamp
        );
    }

    function calculateAccruedIbtPrice(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        return
            IporMath.division(
                IWarrenStorage(_iporConfiguration.getWarrenStorage())
                    .getIndex(asset)
                    .accrueQuasiIbtPrice(calculateTimestamp),
                Constants.YEAR_IN_SECONDS
            );
    }
}
