// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../../interfaces/IWarrenDarcyDataProvider.sol";
import {Constants} from "../../libraries/Constants.sol";
import {IporMath} from "../../libraries/IporMath.sol";
import "../../interfaces/IWarren.sol";

contract WarrenDarcyDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IWarrenDarcyDataProvider
{
    address private _warren;
    address[] internal _assets;

    function initialize(address[] memory assets, address warren) public initializer {
        __Ownable_init();
        _warren = warren;
        _assets = assets;
    }

    function getIndexes() external view override returns (IporFront[] memory) {
        IporFront[] memory indexes = new IporFront[](_assets.length);

        uint256 i = 0;
        for (i; i != _assets.length; i++) {
            indexes[i] = _createIporFront(_assets[i]);
        }
        return indexes;
    }

    function _createIporFront(address asset) internal view returns (IporFront memory iporFront) {
        (uint256 value, uint256 ibtPrice, , , uint256 date) = IWarren(_warren).getIndex(asset);
        iporFront = IporFront(IERC20MetadataUpgradeable(asset).symbol(), value, ibtPrice, date);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
