// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {IAmmPoolsLensBaseV1} from "../../interfaces/IAmmPoolsLensBaseV1.sol";
import {StorageLibBaseV1} from "../../libraries/StorageLibBaseV1.sol";
import {AmmLib} from "../../../libraries/AmmLib.sol";
import {IporContractValidator} from "../../../libraries/IporContractValidator.sol";

import "../../../interfaces/types/AmmTypes.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLensBaseV1 is IAmmPoolsLensBaseV1 {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable iporOracle;

    constructor(address iporOracle_) {
        iporOracle = iporOracle_.checkAddress();
    }

    function getIpTokenExchangeRate(address asset_) external view returns (uint256) {
        StorageLibBaseV1.AssetLensDataValue memory assetLensData = StorageLibBaseV1.getAssetLensDataStorage().value[
            asset_
        ];

        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: asset_,
            assetDecimals: assetLensData.decimals,
            ipToken: assetLensData.ipToken,
            ammStorage: assetLensData.ammStorage,
            ammTreasury: assetLensData.ammTreasury,
            assetManagement: assetLensData.ammVault,
            iporOracle: iporOracle
        });

        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(assetLensData.ammTreasury).getLiquidityPoolBalance();

        return model.getExchangeRate(liquidityPoolBalance);
    }
}
