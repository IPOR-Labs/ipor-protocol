// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {IAmmPoolsLensEthereum} from "../interfaces/IAmmPoolsLensEthereum.sol";
import {StorageLibEthereum} from "../libraries/StorageLibEthereum.sol";
import {AmmLib} from "../../../libraries/AmmLib.sol";
import {IporContractValidator} from "../../../libraries/IporContractValidator.sol";

import "../../../interfaces/types/AmmTypes.sol";
import "../../../base/interfaces/IAmmTreasuryBaseV1.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouterEthereum.sol.
contract AmmPoolsLensEthereum is IAmmPoolsLensEthereum {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address public immutable iporOracle;

    constructor(address iporOracle_) {
        iporOracle = iporOracle_.checkAddress();
    }

    function getIpTokenExchangeRate(address asset_) external view returns (uint256) {
        StorageLibEthereum.AssetLensDataValue memory assetLensData = StorageLibEthereum.getAssetLensDataStorage().value[
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
