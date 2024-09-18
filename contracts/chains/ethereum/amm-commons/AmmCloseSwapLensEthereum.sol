// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmCloseSwapLens.sol";
import "../../../interfaces/IAmmCloseSwapService.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmCloseSwapServicePoolConfigurationLib.sol";
import "../../../base/types/AmmTypesBaseV1.sol";
import "../../../base/amm/libraries/SwapLogicBaseV1.sol";
import "../../../base/amm/libraries/SwapCloseLogicLibBaseV1.sol";
import {StorageLibEthereum} from "../libraries/StorageLibEthereum.sol";
import {AmmCloseSwapLensBaseV1} from "../../../base/amm/lens/AmmCloseSwapLensBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouterEthereum.sol.
contract AmmCloseSwapLensEthereum is AmmCloseSwapLensBaseV1 {
    using Address for address;
    using IporContractValidator for address;
    using SwapLogicBaseV1 for AmmTypesBaseV1.Swap;
    using AmmCloseSwapServicePoolConfigurationLib for IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration;

    constructor(address iporOracle_) AmmCloseSwapLensBaseV1(iporOracle_) {}

    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view override returns (AmmCloseSwapServicePoolConfiguration memory) {
        StorageLibEthereum.AssetServicesValue memory servicesCfg = StorageLibEthereum.getAssetServicesStorage().value[
            asset
        ];

        return _getAmmCloseSwapServicePoolConfiguration(asset, servicesCfg.ammCloseSwapService);
    }

    function getClosingSwapDetails(
        address asset,
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        StorageLibEthereum.AssetServicesValue memory servicesCfg = StorageLibEthereum.getAssetServicesStorage().value[
            asset
        ];

        return _getClosingSwapDetails(
            asset,
            account,
            direction,
            swapId,
            closeTimestamp,
            riskIndicatorsInput,
            servicesCfg.ammCloseSwapService,
            StorageLibEthereum.getMessageSignerStorage().value
        );
    }
}
