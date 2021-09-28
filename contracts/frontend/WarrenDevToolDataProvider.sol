// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IWarrenDevToolDataProvider.sol";
import "../interfaces/IIporAddressesManager.sol";
import {Constants} from '../libraries/Constants.sol';
import {AmmMath} from '../libraries/AmmMath.sol';
import "../interfaces/IWarrenStorage.sol";

contract WarrenDevToolDataProvider is IWarrenDevToolDataProvider {

    IIporAddressesManager public immutable ADDRESSES_MANAGER;

    constructor(IIporAddressesManager addressesManager) {
        ADDRESSES_MANAGER = addressesManager;
    }

    function getIndexes() external override view returns (IporFront[] memory) {
        IWarrenStorage warrenStorage = IWarrenStorage(ADDRESSES_MANAGER.getWarrenStorage());
        address[] memory assets = warrenStorage.getAssets();
        IporFront[] memory _indexes = new IporFront[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.IPOR memory iporIndex = warrenStorage.getIndex(assets[i]);
            _indexes[i] = IporFront(
                IERC20Metadata(iporIndex.asset).symbol(),
                iporIndex.indexValue,
                AmmMath.division(iporIndex.quasiIbtPrice, Constants.YEAR_IN_SECONDS),
                iporIndex.blockTimestamp
            );
        }
        return _indexes;
    }
}