// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/IWarrenDevToolDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import {Constants} from "../libraries/Constants.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IWarren.sol";

contract WarrenDevToolDataProvider is
    OwnableUpgradeable,
    UUPSUpgradeable,
    IWarrenDevToolDataProvider
{
    IIporConfiguration private _iporConfiguration;

    function initialize(IIporConfiguration iporConfiguration)
        public
        initializer
    {
        __Ownable_init();
        _iporConfiguration = iporConfiguration;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getIndexes() external view override returns (IporFront[] memory) {
        IWarren warren = IWarren(_iporConfiguration.getWarren());
        address[] memory assets = warren.getAssets();
        IporFront[] memory indexes = new IporFront[](assets.length);
        uint256 i = 0;
        for (i; i != assets.length; i++) {
            (
                uint256 value,
                uint256 ibtPrice,
                uint256 exponentialMovingAverage,
                uint256 exponentialWeightedMovingVariance,
                uint256 date
            ) = warren.getIndex(assets[i]);

            indexes[i] = IporFront(
                IERC20MetadataUpgradeable(assets[i]).symbol(),
                value,
                ibtPrice,
                exponentialMovingAverage,
                exponentialWeightedMovingVariance,
                date
            );
        }
        return indexes;
    }
}
