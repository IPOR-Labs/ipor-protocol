// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

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

/// @title Abstract contract for closing swap, generation one, characterized by:
/// - no asset management, so also no auto rebalance
abstract contract AmmCloseSwapServiceBaseV1 is IAmmCloseSwapService {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SwapLogicBaseV1 for AmmTypesBaseV1.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    address public immutable asset;
    uint256 public immutable decimals;

    address public immutable iporOracle;
    address public immutable spread;
    address public immutable ammStorage;
    address public immutable ammTreasury;
    /// @dev Asset Management address can be zero address here, if Asset Management is not used, not supported.
    address public immutable ammAssetManagement;

    /// @dev Unwinding fee rate, value represented in 18 decimals. Represents percentage of swap notional.
    uint256 public immutable unwindingFeeRate;
    /// @dev Unwinding fee treasury portion rate, value represented in 18 decimals. Represents percentage of unwinding fee, which is transferred to treasury.
    uint256 public immutable unwindingFeeTreasuryPortionRate;
    /// @dev Maximum length of liquidated swaps per leg, value represented WITHOUT 18 decimals.
    uint256 public immutable liquidationLegLimit;
    /// @dev Time in seconds before maturity allowed to close swap by community.
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByCommunity;
    /// @dev Time in seconds before maturity allowed to close swap by buyer, for tenor 28 days.
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days;
    /// @dev Time in seconds before maturity allowed to close swap by buyer, for tenor 60 days.
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days;
    /// @dev Time in seconds before maturity allowed to close swap by buyer, for tenor 90 days.
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days;
    /// @dev Minimum liquidation threshold to close swap before maturity by community, value represented in 18 decimals.
    uint256 public immutable minLiquidationThresholdToCloseBeforeMaturityByCommunity;
    /// @dev Minimum liquidation threshold to close swap before maturity by buyer, value represented in 18 decimals.
    uint256 public immutable minLiquidationThresholdToCloseBeforeMaturityByBuyer;
    /// @dev Minimum leverage, value represented in 18 decimals.
    uint256 public immutable minLeverage;
    /// @dev Time after open swap when it is allowed to close swap with unwinding, for tenor 28 days, represented in seconds
    uint256 public immutable timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days;
    /// @dev Time after open swap when it is allowed to close swap with unwinding, for tenor 60 days, represented in seconds
    uint256 public immutable timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days;
    /// @dev Time after open swap when it is allowed to close swap with unwinding, for tenor 90 days, represented in seconds
    uint256 public immutable timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days;

    constructor(IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg, address iporOracleInput) {
        asset = poolCfg.asset.checkAddress();
        decimals = poolCfg.decimals;

        iporOracle = iporOracleInput.checkAddress();
        spread = poolCfg.spread.checkAddress();
        ammStorage = poolCfg.ammStorage.checkAddress();
        ammTreasury = poolCfg.ammTreasury.checkAddress();
        ammAssetManagement = poolCfg.assetManagement;

        unwindingFeeRate = poolCfg.unwindingFeeRate;
        unwindingFeeTreasuryPortionRate = poolCfg.unwindingFeeTreasuryPortionRate;
        liquidationLegLimit = poolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        timeBeforeMaturityAllowedToCloseSwapByCommunity = poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity;
        timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days = poolCfg
            .timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days;
        timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days = poolCfg
            .timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days;
        timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days = poolCfg
            .timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days;
        minLiquidationThresholdToCloseBeforeMaturityByCommunity = poolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        minLiquidationThresholdToCloseBeforeMaturityByBuyer = poolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        minLeverage = poolCfg.minLeverage;
        timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days = poolCfg
            .timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days;
        timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days = poolCfg
            .timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days;
        timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days = poolCfg
            .timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days;
    }

    function version() public pure virtual returns (uint256) {
        return 2_002;
    }

    function getPoolConfiguration()
        external
        view
        override
        returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory)
    {
        return _getPoolConfiguration();
    }

    function _getMessageSigner() internal view virtual returns (address);

    function _emergencyCloseSwaps(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
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
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
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
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = SwapLogicBaseV1.calculatePnlPayFixed(
            swap.openTimestamp,
            swap.collateral,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity,
            timestamp,
            ibtPrice
        );

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
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = SwapLogicBaseV1.calculatePnlReceiveFixed(
            swap.openTimestamp,
            swap.collateral,
            swap.notional,
            swap.fixedInterestRate,
            swap.ibtQuantity,
            timestamp,
            ibtPrice
        );

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
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
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
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) internal view returns (AmmInternalTypes.PnlValueStruct memory pnlValueStruct) {
        AmmTypes.SwapClosableStatus closableStatus;

        (closableStatus, pnlValueStruct.swapUnwindRequired) = SwapCloseLogicLibBaseV1.getClosableStatusForSwap(
            AmmTypesBaseV1.ClosableSwapInput({
                account: msg.sender,
                asset: asset,
                closeTimestamp: closeTimestamp,
                swapBuyer: swap.buyer,
                swapOpenTimestamp: swap.openTimestamp,
                swapCollateral: swap.collateral,
                swapTenor: swap.tenor,
                swapState: swap.state,
                swapPnlValueToDate: swapPnlValueToDate,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: timeBeforeMaturityAllowedToCloseSwapByCommunity,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: _getTimeBeforeMaturityAllowedToCloseSwapByBuyer(
                    swap.tenor
                ),
                timeAfterOpenAllowedToCloseSwapWithUnwinding: _getTimeAfterOpenAllowedToCloseSwapWithUnwinding(
                    swap.tenor
                )
            })
        );

        SwapCloseLogicLibBaseV1.validateAllowanceToCloseSwap(closableStatus);

        if (pnlValueStruct.swapUnwindRequired == true) {
            (
                pnlValueStruct.swapUnwindAmount,
                ,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                pnlValueStruct.pnlValue
            ) = SwapCloseLogicLibBaseV1.calculateSwapUnwindWhenUnwindRequired(
                AmmTypesBaseV1.UnwindParams({
                    asset: asset,
                    messageSigner: _getMessageSigner(),
                    spread: spread,
                    ammStorage: ammStorage,
                    ammTreasury: ammTreasury,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: indexValue,
                    swap: swap,
                    unwindingFeeRate: unwindingFeeRate,
                    unwindingFeeTreasuryPortionRate: unwindingFeeTreasuryPortionRate,
                    riskIndicatorsInputs: riskIndicatorsInput
                })
            );
        } else {
            pnlValueStruct.pnlValue = swapPnlValueToDate;
        }
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
    ) internal virtual returns (uint256 wadTransferredToBuyer, uint256 wadPayoutForLiquidator) {
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
        returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory)
    {
        return
            IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: asset,
                decimals: decimals,
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: ammAssetManagement,
                spread: spread,
                unwindingFeeRate: unwindingFeeRate,
                unwindingFeeTreasuryPortionRate: unwindingFeeTreasuryPortionRate,
                maxLengthOfLiquidatedSwapsPerLeg: liquidationLegLimit,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: timeBeforeMaturityAllowedToCloseSwapByCommunity,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                minLeverage: minLeverage,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days
            });
    }

    function _getTimeAfterOpenAllowedToCloseSwapWithUnwinding(
        IporTypes.SwapTenor tenor
    ) internal view returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }

    function _getTimeBeforeMaturityAllowedToCloseSwapByBuyer(
        IporTypes.SwapTenor tenor
    ) internal view returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }
}
