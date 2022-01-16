// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IWarrenFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import {Constants} from "../libraries/Constants.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IWarrenStorage.sol";

contract WarrenFrontendDataProvider is IWarrenFrontendDataProvider {
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
            address itAsset = assets[i];
			DataTypes.IPOR memory iporIndex = warrenStorage.getIndex(itAsset);
            indexes[i] = IporFront(				
                IERC20Metadata(itAsset).symbol(),
                iporIndex.indexValue,
                IporMath.division(
                    iporIndex.quasiIbtPrice,
                    Constants.YEAR_IN_SECONDS
                ),
                iporIndex.blockTimestamp
            );
        }
        return indexes;
    }
}
