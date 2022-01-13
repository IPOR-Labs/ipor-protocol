// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IWarrenDevToolDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import {Constants} from "../libraries/Constants.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IWarrenStorage.sol";

contract WarrenDevToolDataProvider is IWarrenDevToolDataProvider {
    IIporConfiguration private immutable _iporConfiguration;

    constructor(IIporConfiguration initialIporConfiguration) {
        _iporConfiguration = initialIporConfiguration;
    }

    function getIndexes() external view override returns (IporFront[] memory) {
        IWarrenStorage warrenStorage = IWarrenStorage(
            _iporConfiguration.getWarrenStorage()
        );
        address[] memory assets = warrenStorage.getAssets();
        IporFront[] memory indexes = new IporFront[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            DataTypes.IPOR memory iporIndex = warrenStorage.getIndex(assets[i]);
            indexes[i] = IporFront(
                IERC20Metadata(iporIndex.asset).symbol(),
                iporIndex.indexValue,
                IporMath.division(
                    iporIndex.quasiIbtPrice,
                    Constants.YEAR_IN_SECONDS
                ),
                iporIndex.exponentialMovingAverage,
                iporIndex.blockTimestamp
            );
        }
        return indexes;
    }
}
