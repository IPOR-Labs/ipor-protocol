// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IAmmTreasuryBaseV2} from "../../interfaces/IAmmTreasuryBaseV2.sol";
import {AmmCloseSwapServiceBaseV1} from "./AmmCloseSwapServiceBaseV1.sol";
import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmCloseSwapService.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../interfaces/IAmmStorageBaseV1.sol";
import "../../types/AmmTypesBaseV1.sol";
import "../../events/AmmEventsBaseV1.sol";
import "../../../amm/libraries/types/AmmInternalTypes.sol";
import "../../../base/spread/SpreadBaseV1.sol";
import "../libraries/SwapLogicBaseV1.sol";
import "../libraries/SwapCloseLogicLibBaseV1.sol";
import "../../interfaces/ISpreadBaseV1.sol";
import {AssetManagementLogic} from "../../../libraries/AssetManagementLogic.sol";

/// @title Abstract contract for closing swap, generation one,
/// characterized by: with additional asset management logic and rebalance between AmmTreasury and Asset Management (PlasmaVault from Ipor Fusion)
abstract contract AmmCloseSwapServiceBaseV2 is AmmCloseSwapServiceBaseV1 {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput
    ) AmmCloseSwapServiceBaseV1(poolCfg, iporOracleInput){
        poolCfg.assetManagement.checkAddress();

        /// @dev pool asset must match the underlying asset in the AmmAssetManagement vault
        address ammAssetManagementAsset = IERC4626(ammAssetManagement).asset();
        if (ammAssetManagementAsset != asset) {
            revert IporErrors.AssetMismatch(ammAssetManagementAsset, asset);
        }
    }

    function version() public pure virtual override returns (uint256) {
        return 2_003;
    }

    /// @notice Transfer derivative amount to buyer or liquidator.
    /// @param beneficiary Account which will receive the liquidation deposit amount
    /// @param buyer Account which will receive the collateral amount including pnl value (transferAmount)
    /// @param wadLiquidationDepositAmount Amount of liquidation deposit
    /// @param wadTransferAmount Amount of collateral including pnl value
    /// @return wadTransferredToBuyer Final value transferred to buyer, containing collateral and pnl value and if buyer is beneficiary, liquidation deposit amount
    /// @return wadPayoutForLiquidator Final value transferred to liquidator, if liquidator is beneficiary then value is zero
    /// @dev If beneficiary is buyer, then liquidation deposit amount is added to transfer amount.
    /// @dev Input amounts and returned values are represented in 18 decimals.
    /// @dev Method support rebalance between AmmTreasury and AssetManagement (PlasmaVault from Ipor Fusion)
    function _transferDerivativeAmount(
        address beneficiary,
        address buyer,
        uint256 wadLiquidationDepositAmount,
        uint256 wadTransferAmount
    ) internal virtual override returns (uint256 wadTransferredToBuyer, uint256 wadPayoutForLiquidator) {
        if (beneficiary == buyer) {
            wadTransferAmount = wadTransferAmount + wadLiquidationDepositAmount;
        } else {
            /// @dev transfer liquidation deposit amount from AmmTreasury to Liquidator address (beneficiary),
            /// transfer to be made outside this function, to avoid multiple transfers
            wadPayoutForLiquidator = wadLiquidationDepositAmount;
        }

        if (wadTransferAmount + wadPayoutForLiquidator > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadTransferAmount, decimals);

            uint256 totalTransferAmountAssetDecimals = transferAmountAssetDecimals +
                                IporMath.convertWadToAssetDecimals(wadPayoutForLiquidator, decimals);

            uint256 ammTreasuryErc20BalanceBeforeRedeem = IERC20Upgradeable(asset).balanceOf(ammTreasury);

            if (ammTreasuryErc20BalanceBeforeRedeem <= totalTransferAmountAssetDecimals) {
                StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
                    asset
                );

                int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                    IporMath.convertToWad(ammTreasuryErc20BalanceBeforeRedeem, decimals),
                    /// @dev Notice! Plasma Vault underlying asset is the same as the pool asset
                    IporMath.convertToWad(IERC4626(ammAssetManagement).maxWithdraw(ammTreasury), decimals),
                    wadTransferAmount + wadPayoutForLiquidator,
                    /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals,
                    /// example: 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                    uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
                );

                if (rebalanceAmount < 0) {
                    IAmmTreasuryBaseV2(ammTreasury).withdrawFromAssetManagementInternal((-rebalanceAmount).toUint256());

                    /// @dev check if withdraw from asset management is enough to cover transfer amount
                    /// @dev possible case when strategies are paused and assets are temporary locked
                    require(
                        totalTransferAmountAssetDecimals <= IERC20Upgradeable(asset).balanceOf(ammTreasury),
                        AmmErrors.ASSET_MANAGEMENT_WITHDRAW_NOT_ENOUGH
                    );
                }
            }

            IERC20Upgradeable(asset).safeTransferFrom(ammTreasury, buyer, transferAmountAssetDecimals);
            wadTransferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, decimals);
        }
    }
}
