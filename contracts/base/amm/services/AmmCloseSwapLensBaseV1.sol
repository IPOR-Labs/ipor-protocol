// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmTreasury.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AmmLib.sol";
import "../../interfaces/IAmmStorageBaseV1.sol";
import "../../interfaces/IAmmTreasuryBaseV1.sol";
import "../../types/AmmTypesBaseV1.sol";
import "../../events/AmmEventsBaseV1.sol";
import "../../../amm/libraries/types/AmmInternalTypes.sol";
import "../../../base/spread/SpreadBaseV1.sol";
import "../libraries/SwapLogicBaseV1.sol";
import "../libraries/SwapCloseLogicLibBaseV1.sol";
import "../../interfaces/ISpreadBaseV1.sol";
import "./AmmCloseSwapServiceBaseV1.sol";

/// @title Abstract contract for closing swap, generation one, characterized by:
/// - no asset management, so also no auto rebalance
abstract contract AmmCloseSwapLensBaseV1 {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SwapLogicBaseV1 for AmmTypesBaseV1.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    uint256 public immutable version = 2001;

    address public immutable iporOracle;
    address public immutable messageSigner;
    address public immutable closeSwapServiceStEth;

    constructor(address iporOracleInput, address messageSignerInput, address closeSwapServiceStEthInput) {
        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
        closeSwapServiceStEth = closeSwapServiceStEthInput.checkAddress();
    }

    function _getClosingSwapDetails(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration memory poolCfg = AmmCloseSwapServiceBaseV1(
            closeSwapServiceStEth
        ).getPoolConfiguration();

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypesBaseV1.Swap memory swap = IAmmStorageBaseV1(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate = swap.calculatePnl(block.timestamp, accruedIpor.ibtPrice);

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = SwapCloseLogicLibBaseV1
            .getClosableStatusForSwap(
                AmmTypesBaseV1.ClosableSwapInput({
                    account: account,
                    asset: poolCfg.asset,
                    closeTimestamp: closeTimestamp,
                    swapBuyer: swap.buyer,
                    swapOpenTimestamp: swap.openTimestamp,
                    swapCollateral: swap.collateral,
                    swapTenor: swap.tenor,
                    swapState: swap.state,
                    swapPnlValueToDate: swapPnlValueToDate,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: poolCfg
                        .minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: poolCfg
                        .timeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer,
                    timeAfterOpenAllowedToCloseSwapWithUnwinding: poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwinding
                })
            );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = SwapCloseLogicLibBaseV1.calculateSwapUnwindWhenUnwindRequired(
                AmmTypesBaseV1.UnwindParams({
                    asset: poolCfg.asset,
                    messageSigner: messageSigner,
                    spread: poolCfg.spread,
                    ammStorage: poolCfg.ammStorage,
                    ammTreasury: poolCfg.ammTreasury,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: accruedIpor.indexValue,
                    swap: swap,
                    unwindingFeeRate: poolCfg.unwindingFeeRate,
                    unwindingFeeTreasuryPortionRate: poolCfg.unwindingFeeTreasuryPortionRate,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }
}
