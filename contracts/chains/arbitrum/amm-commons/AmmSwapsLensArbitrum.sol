// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../../../interfaces/IAmmSwapsLens.sol";
import "../../../base/amm/libraries/AmmSwapsLensLibBaseV1.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/RiskIndicatorsValidatorLib.sol";
import "../../../libraries/AmmLib.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmSwapsLensArbitrum is IAmmSwapsLens {
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    address public immutable iporOracle;

    constructor(address iporOracle_) {
        iporOracle = iporOracle_.checkAddress();
    }

    function getSwapLensPoolConfiguration(
        address asset
    ) external view override returns (SwapLensPoolConfiguration memory) {
        return _getSwapLensPoolConfiguration(asset);
    }

    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        StorageLibArbitrum.AssetLensDataValue storage lensPoolCfg = StorageLibArbitrum.getAssetLensDataStorage().value[
            asset
        ];
        return AmmSwapsLensLibBaseV1.getSwaps(iporOracle, lensPoolCfg.ammStorage, asset, account, offset, chunkSize);
    }

    function getPnlPayFixed(address asset, uint256 swapId) external view override returns (int256) {
        StorageLibArbitrum.AssetLensDataValue storage lensPoolCfg = StorageLibArbitrum.getAssetLensDataStorage().value[
            asset
        ];
        return AmmSwapsLensLibBaseV1.getPnlPayFixed(iporOracle, lensPoolCfg.ammStorage, asset, swapId);
    }

    function getPnlReceiveFixed(address asset, uint256 swapId) external view override returns (int256) {
        StorageLibArbitrum.AssetLensDataValue storage lensPoolCfg = StorageLibArbitrum.getAssetLensDataStorage().value[
            asset
        ];
        return AmmSwapsLensLibBaseV1.getPnlReceiveFixed(iporOracle, lensPoolCfg.ammStorage, asset, swapId);
    }

    function getSoap(
        address asset
    ) external view override returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        StorageLibArbitrum.AssetLensDataValue storage lensPoolCfg = StorageLibArbitrum.getAssetLensDataStorage().value[
            asset
        ];

        AmmTypes.AmmPoolCoreModel memory ammCoreModel;

        ammCoreModel.asset = asset;
        ammCoreModel.ammStorage = lensPoolCfg.ammStorage;
        ammCoreModel.iporOracle = iporOracle;

        (soapPayFixed, soapReceiveFixed, soap) = ammCoreModel.getSoap();
    }

    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional,
        AmmTypes.RiskIndicatorsInputs calldata payFixedRiskIndicatorsInputs,
        AmmTypes.RiskIndicatorsInputs calldata receiveFixedRiskIndicatorsInputs
    ) external view override returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) {
        require(notional > 0, AmmErrors.INVALID_NOTIONAL);

        SwapLensPoolConfiguration memory poolCfg = _getSwapLensPoolConfiguration(asset);

        address messageSigner = StorageLibArbitrum.getMessageSignerStorage().value;

        (uint256 indexValue, , ) = IIporOracle(iporOracle).getIndex(asset);

        AmmTypes.OpenSwapRiskIndicators memory swapRiskIndicatorsPayFixed = payFixedRiskIndicatorsInputs.verify(
            asset,
            uint256(tenor),
            uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
            messageSigner
        );

        AmmTypes.OpenSwapRiskIndicators memory swapRiskIndicatorsReceiveFixed = receiveFixedRiskIndicatorsInputs.verify(
            asset,
            uint256(tenor),
            uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
            messageSigner
        );

        (offeredRatePayFixed, offeredRateReceiveFixed) = AmmSwapsLensLibBaseV1.getOfferedRate(
            poolCfg,
            indexValue,
            tenor,
            notional,
            messageSigner,
            swapRiskIndicatorsPayFixed,
            swapRiskIndicatorsReceiveFixed
        );
    }

    function getBalancesForOpenSwap(
        address asset
    ) external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        StorageLibArbitrum.AssetLensDataValue storage lensPoolCfg = StorageLibArbitrum.getAssetLensDataStorage().value[
            asset
        ];

        return AmmSwapsLensLibBaseV1.getBalancesForOpenSwap(lensPoolCfg.ammStorage, lensPoolCfg.ammTreasury);
    }

    function _getSwapLensPoolConfiguration(address asset_) internal view returns (SwapLensPoolConfiguration memory) {
        StorageLibArbitrum.AssetLensDataValue memory lensPoolCfg = StorageLibArbitrum.getAssetLensDataStorage().value[
            asset_
        ];
        return
            SwapLensPoolConfiguration({
                asset: asset_,
                ammStorage: lensPoolCfg.ammStorage,
                ammTreasury: lensPoolCfg.ammTreasury,
                spread: lensPoolCfg.spread
            });
    }
}
