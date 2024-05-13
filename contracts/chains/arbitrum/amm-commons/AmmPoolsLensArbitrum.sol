// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IAmmPoolsLensArbitrum} from "../interfaces/IAmmPoolsLensArbitrum.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";
import {AmmLib} from "../../../libraries/AmmLib.sol";
import {IporContractValidator} from "../../../libraries/IporContractValidator.sol";

import "../../../interfaces/types/AmmTypes.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";



/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmPoolsLensArbitrum is IAmmPoolsLensArbitrum {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    function getIpTokenExchangeRate(address asset_) external view returns (uint256) {
        StorageLibArbitrum.AssetLensDataValue memory assetLensData = StorageLibArbitrum.getAssetLensDataStorage().value[asset_];

        address iporOracle = StorageLibArbitrum.getIporIndexOracleStorage().value;

        AmmTypes.AmmPoolCoreModel memory model = AmmTypes.AmmPoolCoreModel({
            asset: asset_,
            assetDecimals: assetLensData.decimals,
            ipToken: assetLensData.ipToken,
            ammStorage: assetLensData.ammStorage,
            ammTreasury: assetLensData.ammTreasury,
            assetManagement: assetLensData.vault,
            iporOracle: iporOracle
        });

        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(assetLensData.ammTreasury).getLiquidityPoolBalance();

        return model.getExchangeRate(liquidityPoolBalance);
    }
}
