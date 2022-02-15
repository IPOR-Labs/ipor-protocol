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
    address private _warren;
    address internal _assetDai;
    address internal _assetUsdc;
    address internal _assetUsdt;

    function initialize(
        address warren,
        address assetDai,
        address assetUsdt,
        address assetUsdc
    ) public initializer {
        __Ownable_init();
        _warren = warren;
        _assetDai = assetDai;
        _assetUsdc = assetUsdc;
        _assetUsdt = assetUsdt;
    }

    function getIndexes() external view override returns (IporFront[] memory) {
        IporFront[] memory indexes = new IporFront[](3);
        indexes[0] = _createIporFrond(_assetDai);
        indexes[1] = _createIporFrond(_assetUsdt);
        indexes[2] = _createIporFrond(_assetUsdc);
        return indexes;
    }

    function _createIporFrond(address asset)
        internal
        view
        returns (IporFront memory iporFront)
    {
        (
            uint256 value,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 date
        ) = IWarren(_warren).getIndex(asset);

        iporFront = IporFront(
            IERC20MetadataUpgradeable(asset).symbol(),
            value,
            ibtPrice,
            exponentialMovingAverage,
            exponentialWeightedMovingVariance,
            date
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
