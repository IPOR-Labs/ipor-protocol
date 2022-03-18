// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../../interfaces/types/DarcyTypes.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IWarren.sol";
import "../../interfaces/IWarrenDarcyDataProvider.sol";
import "../../security/IporOwnableUpgradeable.sol";

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

    function getIndexes() external view override returns (DarcyTypes.IporFront[] memory) {
        DarcyTypes.IporFront[] memory indexes = new DarcyTypes.IporFront[](_assets.length);

        uint256 assetLength = _assets.length;
        for (uint256 i = 0; i != assetLength; i++) {
            indexes[i] = _createIporFront(_assets[i]);
        }
        return indexes;
    }

    function _createIporFront(address asset)
        internal
        view
        returns (DarcyTypes.IporFront memory iporFront)
    {
        (uint256 value, uint256 ibtPrice, , , uint256 date) = IWarren(_warren).getIndex(asset);
        iporFront = DarcyTypes.IporFront(
            IERC20MetadataUpgradeable(asset).symbol(),
            asset,
            value,
            ibtPrice,
            date
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
