// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IWarrenFrontendDataProvider.sol";
import "../interfaces/IIporConfiguration.sol";
import {Constants} from "../libraries/Constants.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../interfaces/IWarren.sol";

contract WarrenFrontendDataProvider is IWarrenFrontendDataProvider {
    IIporConfiguration private immutable _iporConfiguration;

    constructor(IIporConfiguration initialIporConfiguration) {
        _iporConfiguration = initialIporConfiguration;
    }

    function getIndexes() external view override returns (IporFront[] memory) {
        IWarren warren = IWarren(
            _iporConfiguration.getWarren()
        );
        address[] memory assets = warren.getAssets();
        IporFront[] memory indexes = new IporFront[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            address itAsset = assets[i];
			(
                uint256 value,
                uint256 ibtPrice,
                ,
                ,
                uint256 date
            ) = warren.getIndex(itAsset);
            indexes[i] = IporFront(				
                IERC20Metadata(itAsset).symbol(),
                value,
                ibtPrice,
                date
            );
        }
        return indexes;
    }
}
