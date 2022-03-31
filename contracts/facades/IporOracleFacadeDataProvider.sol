// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../interfaces/types/IporOracleFacadeTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IIporOracleFacadeDataProvider.sol";
import "../security/IporOwnableUpgradeable.sol";

contract IporOracleFacadeDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IIporOracleFacadeDataProvider
{
    address private _iporOracle;
    address[] internal _assets;

    function initialize(address[] memory assets, address iporOracle) public initializer {
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        __Ownable_init();
        _iporOracle = iporOracle;
        _assets = assets;
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getIndexes()
        external
        view
        override
        returns (IporOracleFacadeTypes.IporFront[] memory)
    {
        IporOracleFacadeTypes.IporFront[] memory indexes = new IporOracleFacadeTypes.IporFront[](
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
        returns (IporOracleFacadeTypes.IporFront memory iporFront)
    {
        (uint256 value, uint256 ibtPrice, , , uint256 date) = IIporOracle(_iporOracle).getIndex(
            asset
        );
        iporFront = IporOracleFacadeTypes.IporFront(
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
