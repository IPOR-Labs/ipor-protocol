// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/types/WarrenFacadeTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IWarren.sol";
import "../interfaces/IWarrenFacadeDataProvider.sol";
import "../security/IporOwnableUpgradeable.sol";

contract WarrenFacadeDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IWarrenFacadeDataProvider
{
    address private _warren;
    address[] internal _assets;

    function initialize(address[] memory assets, address warren) public initializer {
        require(warren != address(0), IporErrors.WRONG_ADDRESS);
        __Ownable_init();
        _warren = warren;
        _assets = assets;
    }

    function getIndexes() external view override returns (WarrenFacadeTypes.IporFront[] memory) {
        WarrenFacadeTypes.IporFront[] memory indexes = new WarrenFacadeTypes.IporFront[](
            _assets.length
        );

        uint256 assetLength = _assets.length;
        for (uint256 i = 0; i != assetLength; i++) {
            indexes[i] = _createIporFront(_assets[i]);
        }
        return indexes;
    }

    function _createIporFront(address asset)
        internal
        view
        returns (WarrenFacadeTypes.IporFront memory iporFront)
    {
        (uint256 value, uint256 ibtPrice, , , uint256 date) = IWarren(_warren).getIndex(asset);
        iporFront = WarrenFacadeTypes.IporFront(
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
