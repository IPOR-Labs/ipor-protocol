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
import "../../interfaces/ISpreadBaseV1.sol";

/// @title Abstract contract for closing swap, generation one, characterized by:
/// - no asset management, so also no auto rebalance
abstract contract AmmCloseSwapServiceBaseV1 {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SwapLogicBaseV1 for AmmTypesBaseV1.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    uint256 public immutable version = 2001;

    address public immutable asset;
    uint256 public immutable decimals;

    address public immutable messageSigner;
    address public immutable iporOracle;
    address public immutable spread;
    address public immutable ammStorage;
    address public immutable ammTreasury;

    /// @dev Unwinding fee rate, value represented in 18 decimals. Represents percentage of swap notional.
    uint256 public immutable unwindingFeeRate;
    /// @dev Unwinding fee treasury portion rate, value represented in 18 decimals. Represents percentage of unwinding fee, which is transferred to treasury.
    uint256 public immutable unwindingFeeTreasuryPortionRate;
    /// @dev Maximum length of liquidated swaps per leg, value represented WITHOUT 18 decimals.
    uint256 public immutable liquidationLegLimit;
    /// @dev Time in seconds before maturity allowed to close swap by community.
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByCommunity;
    /// @dev Time in seconds before maturity allowed to close swap by buyer.
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByBuyer;
    /// @dev Minimum liquidation threshold to close swap before maturity by community, value represented in 18 decimals.
    uint256 public immutable minLiquidationThresholdToCloseBeforeMaturityByCommunity;
    /// @dev Minimum liquidation threshold to close swap before maturity by buyer, value represented in 18 decimals.
    uint256 public immutable minLiquidationThresholdToCloseBeforeMaturityByBuyer;
    /// @dev Minimum leverage, value represented in 18 decimals.
    uint256 public immutable minLeverage;
    /// @dev Time after open swap when it is allowed to close swap with unwinding, represented in seconds
    uint256 public immutable timeAfterOpenAllowedToCloseSwapWithUnwinding;

    constructor(
        AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput
    ) {
        asset = poolCfg.asset.checkAddress();
        decimals = poolCfg.decimals;

        messageSigner = messageSignerInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
        spread = poolCfg.spread.checkAddress();
        ammStorage = poolCfg.ammStorage.checkAddress();
        ammTreasury = poolCfg.ammTreasury.checkAddress();

        unwindingFeeRate = poolCfg.unwindingFeeRate;
        unwindingFeeTreasuryPortionRate = poolCfg.unwindingFeeTreasuryPortionRate;
        liquidationLegLimit = poolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        timeBeforeMaturityAllowedToCloseSwapByCommunity = poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity;
        timeBeforeMaturityAllowedToCloseSwapByBuyer = poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        minLiquidationThresholdToCloseBeforeMaturityByCommunity = poolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        minLiquidationThresholdToCloseBeforeMaturityByBuyer = poolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        minLeverage = poolCfg.minLeverage;
        timeAfterOpenAllowedToCloseSwapWithUnwinding = poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwinding;
    }

    function _getClosingSwapDetails(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration();

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypesBaseV1.Swap memory swap = IAmmStorageBaseV1(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate = swap.calculatePnl(block.timestamp, accruedIpor.ibtPrice);

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = SwapLogicBaseV1
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

                //            swap, account, swapPnlValueToDate, closeTimestamp, poolCfg
            );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = _calculateSwapUnwindWhenUnwindRequired(
                AmmTypesBaseV1.UnwindParams({
                    messageSigner: messageSigner,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: accruedIpor.indexValue,
                    swap: swap,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }

    function _emergencyCloseSwaps(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    )
        internal
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            msg.sender,
            payFixedSwapIds,
            receiveFixedSwapIds,
            riskIndicatorsInput
        );
    }

    function _closeSwaps(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    )
        internal
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        require(
            payFixedSwapIds.length <= liquidationLegLimit && receiveFixedSwapIds.length <= liquidationLegLimit,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        uint256 payoutForLiquidatorPayFixed;
        uint256 payoutForLiquidatorReceiveFixed;

        (payoutForLiquidatorPayFixed, closedPayFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            payFixedSwapIds,
            riskIndicatorsInput
        );

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            receiveFixedSwapIds,
            riskIndicatorsInput
        );

        _transferLiquidationDepositAmount(beneficiary, payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed);
    }

    function _closeSwapPayFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypesBaseV1.Swap memory swap,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = swap.calculatePnlPayFixed(timestamp, ibtPrice);

        AmmInternalTypes.PnlValueStruct memory pnlValueStruct = _preparePnlValueStructForClose(
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            riskIndicatorsInput
        );

        ISpreadBaseV1(spread).updateTimeWeightedNotionalOnClose(
            uint256(swap.direction),
            swap.tenor,
            swap.notional,
            IAmmStorageBaseV1(ammStorage).updateStorageWhenCloseSwapPayFixedInternal(
                swap,
                pnlValueStruct.pnlValue,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                timestamp
            ),
            ammStorage
        );

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPnlValue(
            beneficiary,
            pnlValueStruct.pnlValue -
                pnlValueStruct.swapUnwindFeeLPAmount.toInt256() -
                pnlValueStruct.swapUnwindFeeTreasuryAmount.toInt256(),
            swap
        );

        if (pnlValueStruct.swapUnwindRequired) {
            emit AmmEventsBaseV1.SwapUnwind(
                asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit AmmEventsBaseV1.CloseSwap(swap.id, asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapReceiveFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypesBaseV1.Swap memory swap,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = swap.calculatePnlReceiveFixed(timestamp, ibtPrice);

        AmmInternalTypes.PnlValueStruct memory pnlValueStruct = _preparePnlValueStructForClose(
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            riskIndicatorsInput
        );

        SpreadBaseV1(spread).updateTimeWeightedNotionalOnClose(
            uint256(swap.direction),
            swap.tenor,
            swap.notional,
            IAmmStorageBaseV1(ammStorage).updateStorageWhenCloseSwapReceiveFixedInternal(
                swap,
                pnlValueStruct.pnlValue,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                timestamp
            ),
            ammStorage
        );

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPnlValue(
            beneficiary,
            pnlValueStruct.pnlValue -
                pnlValueStruct.swapUnwindFeeLPAmount.toInt256() -
                pnlValueStruct.swapUnwindFeeTreasuryAmount.toInt256(),
            swap
        );

        if (pnlValueStruct.swapUnwindRequired) {
            emit AmmEventsBaseV1.SwapUnwind(
                asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit AmmEventsBaseV1.CloseSwap(swap.id, asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPerLeg(
        address beneficiary,
        AmmTypes.SwapDirection direction,
        uint256[] memory swapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 swapIdsLength = swapIds.length;
        require(swapIdsLength <= liquidationLegLimit, AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED);

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIdsLength);
        AmmTypesBaseV1.Swap memory swap;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(block.timestamp, asset);
        uint256 swapId;

        for (uint256 i; i != swapIdsLength; ) {
            swapId = swapIds[i];
            require(swapId > 0, AmmErrors.INCORRECT_SWAP_ID);

            swap = IAmmStorageBaseV1(ammStorage).getSwap(direction, swapId);

            if (swap.state == IporTypes.SwapState.ACTIVE) {
                if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
                    payoutForLiquidator += _closeSwapPayFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        riskIndicatorsInput
                    );
                } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
                    payoutForLiquidator += _closeSwapReceiveFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        riskIndicatorsInput
                    );
                } else {
                    revert(AmmErrors.UNSUPPORTED_DIRECTION);
                }
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Transfer sum of all liquidation deposits to liquidator
    /// @param liquidator address of liquidator
    /// @param liquidationDepositAmount liquidation deposit amount, value represented in 18 decimals
    function _transferLiquidationDepositAmount(address liquidator, uint256 liquidationDepositAmount) internal {
        if (liquidationDepositAmount > 0) {
            IERC20Upgradeable(asset).safeTransferFrom(
                ammTreasury,
                liquidator,
                IporMath.convertWadToAssetDecimals(liquidationDepositAmount, decimals)
            );
        }
    }

    function _preparePnlValueStructForClose(
        uint256 closeTimestamp,
        int256 swapPnlValueToDate,
        uint256 indexValue,
        AmmTypesBaseV1.Swap memory swap,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal view returns (AmmInternalTypes.PnlValueStruct memory pnlValueStruct) {
        AmmTypes.SwapClosableStatus closableStatus;
        AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration();

        (closableStatus, pnlValueStruct.swapUnwindRequired) = SwapLogicBaseV1.getClosableStatusForSwap(
            AmmTypesBaseV1.ClosableSwapInput({
                account: msg.sender,
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

        _validateAllowanceToCloseSwap(closableStatus);

        if (pnlValueStruct.swapUnwindRequired == true) {
            (
                pnlValueStruct.swapUnwindAmount,
                ,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                pnlValueStruct.pnlValue
            ) = _calculateSwapUnwindWhenUnwindRequired(
                AmmTypesBaseV1.UnwindParams({
                    messageSigner: messageSigner,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: indexValue,
                    swap: swap,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            pnlValueStruct.pnlValue = swapPnlValueToDate;
        }
    }

    /// @notice Calculate swap unwind when unwind is required.
    /// @param unwindParams unwind parameters required to calculate swap unwind pnl value.
    /// @return swapUnwindPnlValue swap unwind PnL value
    /// @return swapUnwindFeeAmount swap unwind opening fee amount, sum of swapUnwindFeeLPAmount and swapUnwindFeeTreasuryAmount
    /// @return swapUnwindFeeLPAmount swap unwind opening fee LP amount
    /// @return swapUnwindFeeTreasuryAmount swap unwind opening fee treasury amount
    /// @return swapPnlValue swap PnL value includes swap PnL to date, swap unwind PnL value, this value NOT INCLUDE swap unwind fee amount.
    function _calculateSwapUnwindWhenUnwindRequired(
        AmmTypesBaseV1.UnwindParams memory unwindParams
    )
        internal
        view
        returns (
            int256 swapUnwindPnlValue,
            uint256 swapUnwindFeeAmount,
            uint256 swapUnwindFeeLPAmount,
            uint256 swapUnwindFeeTreasuryAmount,
            int256 swapPnlValue
        )
    {
        //TODO: check if can unwind

        AmmTypes.OpenSwapRiskIndicators memory oppositeRiskIndicators;

        if (unwindParams.swap.direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            oppositeRiskIndicators = unwindParams.riskIndicatorsInputs.receiveFixed.verify(
                asset,
                uint256(unwindParams.swap.tenor),
                uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
                unwindParams.messageSigner
            );
            /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
            swapUnwindPnlValue = _calculateSwapUnwindPnlValueNormalized(
                unwindParams,
                AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
                oppositeRiskIndicators
            );
        } else if (unwindParams.swap.direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            oppositeRiskIndicators = unwindParams.riskIndicatorsInputs.payFixed.verify(
                asset,
                uint256(unwindParams.swap.tenor),
                uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
                unwindParams.messageSigner
            );
            /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
            swapUnwindPnlValue = _calculateSwapUnwindPnlValueNormalized(
                unwindParams,
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                oppositeRiskIndicators
            );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        swapPnlValue = IporSwapLogic.normalizePnlValue(
            unwindParams.swap.collateral,
            unwindParams.swapPnlValueToDate + swapUnwindPnlValue
        );

        /// @dev swap unwind fee amount is independent of the swap unwind pnl value, takes into consideration notional.
        swapUnwindFeeAmount = SwapLogicBaseV1.calculateSwapUnwindOpeningFeeAmount(
            unwindParams.swap,
            unwindParams.closeTimestamp,
            unwindingFeeRate
        );

        require(
            unwindParams.swap.collateral.toInt256() + swapPnlValue > swapUnwindFeeAmount.toInt256(),
            AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP
        );

        (swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount) = IporSwapLogic.splitOpeningFeeAmount(
            swapUnwindFeeAmount,
            unwindingFeeTreasuryPortionRate
        );

        swapPnlValue = unwindParams.swapPnlValueToDate + swapUnwindPnlValue;
    }

    function _calculateSwapUnwindPnlValueNormalized(
        AmmTypesBaseV1.UnwindParams memory unwindParams,
        AmmTypes.SwapDirection oppositeDirection,
        AmmTypes.OpenSwapRiskIndicators memory oppositeRiskIndicators
    ) internal view returns (int256) {
        AmmTypesBaseV1.AmmBalanceForOpenSwap memory balance = IAmmStorageBaseV1(ammStorage).getBalancesForOpenSwap();
        uint256 liquidityPoolBalance = IAmmTreasuryBaseV1(ammTreasury).getLiquidityPoolBalance();

        return
            IporSwapLogic.normalizePnlValue(
                unwindParams.swap.collateral,
                unwindParams.swap.calculateSwapUnwindPnlValue(
                    unwindParams.closeTimestamp,
                    ISpreadBaseV1(spread).calculateOfferedRate(
                        oppositeDirection,
                        ISpreadBaseV1.SpreadInputs({
                            asset: asset,
                            swapNotional: unwindParams.swap.notional,
                            demandSpreadFactor: oppositeRiskIndicators.demandSpreadFactor,
                            baseSpreadPerLeg: oppositeRiskIndicators.baseSpreadPerLeg,
                            totalCollateralPayFixed: balance.totalCollateralPayFixed,
                            totalCollateralReceiveFixed: balance.totalCollateralReceiveFixed,
                            liquidityPoolBalance: liquidityPoolBalance,
                            iporIndexValue: unwindParams.indexValue,
                            fixedRateCapPerLeg: oppositeRiskIndicators.fixedRateCapPerLeg,
                            tenor: unwindParams.swap.tenor
                        })
                    )
                )
            );
    }

    /**
     * @notice Function that transfers payout of the swap to the owner.
     * @dev Function:
     * # checks if swap profit, loss or achieve maturity allows for liquidation
     * # checks if swap's payout is larger than the collateral used to open it
     * # should the payout be larger than the collateral then it transfers payout to the buyer
     * @param swap - Derivative struct
     * @param pnlValue - Net earnings of the derivative. Can be positive (swap has a positive earnings) or negative (swap looses), value represented in 18 decimals, value include potential unwind fee.
     **/
    function _transferTokensBasedOnPnlValue(
        address beneficiary,
        int256 pnlValue,
        AmmTypesBaseV1.Swap memory swap
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPnlValue = IporMath.absoluteValue(pnlValue);

        if (pnlValue > 0) {
            //Buyer earns, AmmTreasury looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.wadLiquidationDepositAmount,
                swap.collateral + absPnlValue
            );
        } else {
            //AmmTreasury earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.wadLiquidationDepositAmount,
                swap.collateral - absPnlValue
            );
        }
    }

    function _validateAllowanceToCloseSwap(AmmTypes.SwapClosableStatus closableStatus) internal pure {
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_ALREADY_CLOSED) {
            revert(AmmErrors.INCORRECT_SWAP_STATUS);
        }
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE) {
            revert(AmmErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR);
        }
        if (closableStatus == AmmTypes.SwapClosableStatus.SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY) {
            revert(AmmErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY);
        }
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
    function _transferDerivativeAmount(
        address beneficiary,
        address buyer,
        uint256 wadLiquidationDepositAmount,
        uint256 wadTransferAmount
    ) internal returns (uint256 wadTransferredToBuyer, uint256 wadPayoutForLiquidator) {
        if (beneficiary == buyer) {
            wadTransferAmount = wadTransferAmount + wadLiquidationDepositAmount;
        } else {
            /// @dev transfer liquidation deposit amount from AmmTreasury to Liquidator address (beneficiary),
            /// transfer to be made outside this function, to avoid multiple transfers
            wadPayoutForLiquidator = wadLiquidationDepositAmount;
        }

        if (wadTransferAmount > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadTransferAmount, decimals);
            IERC20Upgradeable(asset).safeTransferFrom(ammTreasury, buyer, transferAmountAssetDecimals);
            wadTransferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, decimals);
        }
    }

    function _getPoolConfiguration()
        internal
        view
        returns (AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration memory)
    {
        return
            AmmTypesBaseV1.AmmCloseSwapServicePoolConfiguration({
                spread: spread,
                asset: asset,
                decimals: decimals,
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                unwindingFeeRate: unwindingFeeRate,
                unwindingFeeTreasuryPortionRate: unwindingFeeTreasuryPortionRate,
                maxLengthOfLiquidatedSwapsPerLeg: liquidationLegLimit,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: timeBeforeMaturityAllowedToCloseSwapByCommunity,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: timeBeforeMaturityAllowedToCloseSwapByBuyer,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                minLeverage: minLeverage,
                timeAfterOpenAllowedToCloseSwapWithUnwinding: timeAfterOpenAllowedToCloseSwapWithUnwinding
            });
    }
}
