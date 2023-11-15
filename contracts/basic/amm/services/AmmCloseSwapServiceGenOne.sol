// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../interfaces/types/IporTypes.sol";
import "../../../interfaces/types/AmmTypes.sol";
import "../../../interfaces/IIporOracle.sol";
import "../../../interfaces/IAmmTreasury.sol";
import "../../interfaces/IAmmStorageGenOne.sol";
import "../../../interfaces/IAmmCloseSwapService.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/math/IporMath.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/AssetManagementLogic.sol";
import "../../../libraries/AmmLib.sol";
import "../../../governance/AmmConfigurationManager.sol";
import "../../../security/OwnerManager.sol";
import "../libraries/SwapEventsGenOne.sol";
import "../../../amm/libraries/types/AmmInternalTypes.sol";
import "../../../amm/spread/ISpreadCloseSwapService.sol";
import "../libraries/SwapLogicGenOne.sol";
import "../../types/AmmTypesGenOne.sol";
import "../../events/AmmEventsGenOne.sol";

//TODO: other names proposition: AmmCloseSwapS1G1, AmmCloseSwapServiceOneGenOne, AmmCloseSwapServiceOneGenerationOne
abstract contract AmmCloseSwapServiceGenOne {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SwapLogicGenOne for AmmTypesGenOne.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    uint256 public immutable version = 1;

    address public immutable asset;
    uint256 public immutable decimals;

    address public immutable messageSigner;
    address public immutable iporOracle;
    address public immutable spread;
    address public immutable ammStorage;
    address public immutable ammTreasury;

    uint256 public immutable unwindingFeeRate;
    uint256 public immutable unwindingFeeTreasuryPortionRate;
    uint256 public immutable liquidationLegLimit;
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 public immutable timeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 public immutable minLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 public immutable minLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 public immutable minLeverage;

    constructor(
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address spreadInput
    ) {
        asset = poolCfg.asset.checkAddress();
        decimals = poolCfg.decimals;

        messageSigner = messageSignerInput.checkAddress();
        iporOracle = iporOracleInput.checkAddress();
        spread = spreadInput.checkAddress();
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
    }

    function _getClosingSwapDetails(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration();

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypesGenOne.Swap memory swap = IAmmStorageGenOne(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate = swap.calculatePnl(block.timestamp, accruedIpor.ibtPrice);

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = SwapLogicGenOne
            .getClosableStatusForSwap(swap, account, swapPnlValueToDate, closeTimestamp, poolCfg);

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = SwapLogicGenOne.calculateSwapUnwindWhenUnwindRequired(
                AmmTypesGenOne.UnwindParams({
                    messageSigner: messageSigner,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: accruedIpor.indexValue,
                    swap: swap,
                    poolCfg: poolCfg,
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
            _getPoolConfiguration(),
            riskIndicatorsInput
        );
    }

    function _closeSwaps(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    )
        internal
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        require(
            payFixedSwapIds.length <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg &&
                receiveFixedSwapIds.length <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        uint256 payoutForLiquidatorPayFixed;
        uint256 payoutForLiquidatorReceiveFixed;

        (payoutForLiquidatorPayFixed, closedPayFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            payFixedSwapIds,
            poolCfg,
            riskIndicatorsInput
        );

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            receiveFixedSwapIds,
            poolCfg,
            riskIndicatorsInput
        );

        _transferLiquidationDepositAmount(beneficiary, payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed);
    }

    function _closeSwapPayFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypesGenOne.Swap memory swap,
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = swap.calculatePnlPayFixed(timestamp, ibtPrice);

        AmmInternalTypes.PnlValueStruct memory pnlValueStruct = _preparePnlValueStructForClose(
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            poolCfg,
            riskIndicatorsInput
        );

        ISpreadCloseSwapService(spread).updateTimeWeightedNotionalOnClose(
            asset,
            uint256(swap.direction),
            swap.tenor,
            swap.notional,
            IAmmStorageGenOne(ammStorage).updateStorageWhenCloseSwapPayFixedInternal(
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
            emit AmmEventsGenOne.SwapUnwind(
                asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit AmmEventsGenOne.CloseSwap(swap.id, asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapReceiveFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypesGenOne.Swap memory swap,
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = swap.calculatePnlReceiveFixed(timestamp, ibtPrice);

        AmmInternalTypes.PnlValueStruct memory pnlValueStruct = _preparePnlValueStructForClose(
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            poolCfg,
            riskIndicatorsInput
        );

        ISpreadCloseSwapService(spread).updateTimeWeightedNotionalOnClose(
            asset,
            uint256(swap.direction),
            swap.tenor,
            swap.notional,
            IAmmStorageGenOne(ammStorage).updateStorageWhenCloseSwapReceiveFixedInternal(
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
            emit AmmEventsGenOne.SwapUnwind(
                asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit AmmEventsGenOne.CloseSwap(swap.id, asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPerLeg(
        address beneficiary,
        AmmTypes.SwapDirection direction,
        uint256[] memory swapIds,
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 swapIdsLength = swapIds.length;
        require(
            swapIdsLength <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIdsLength);
        AmmTypesGenOne.Swap memory swap;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );
        uint256 swapId;

        for (uint256 i; i != swapIdsLength; ) {
            swapId = swapIds[i];
            require(swapId > 0, AmmErrors.INCORRECT_SWAP_ID);

            swap = IAmmStorageGenOne(poolCfg.ammStorage).getSwap(direction, swapId);

            if (swap.state == IporTypes.SwapState.ACTIVE) {
                if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
                    payoutForLiquidator += _closeSwapPayFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        poolCfg,
                        riskIndicatorsInput
                    );
                } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
                    payoutForLiquidator += _closeSwapReceiveFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        poolCfg,
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
        AmmTypesGenOne.Swap memory swap,
        AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInput
    ) internal view returns (AmmInternalTypes.PnlValueStruct memory pnlValueStruct) {
        AmmTypes.SwapClosableStatus closableStatus;

        (closableStatus, pnlValueStruct.swapUnwindRequired) = SwapLogicGenOne.getClosableStatusForSwap(
            swap,
            msg.sender,
            swapPnlValueToDate,
            closeTimestamp,
            poolCfg
        );

        _validateAllowanceToCloseSwap(closableStatus);

        if (pnlValueStruct.swapUnwindRequired == true) {
            (
                pnlValueStruct.swapUnwindAmount,
                ,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                pnlValueStruct.pnlValue
            ) = SwapLogicGenOne.calculateSwapUnwindWhenUnwindRequired(
                AmmTypesGenOne.UnwindParams({
                    messageSigner: messageSigner,
                    closeTimestamp: closeTimestamp,
                    swapPnlValueToDate: swapPnlValueToDate,
                    indexValue: indexValue,
                    swap: swap,
                    poolCfg: poolCfg,
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
        AmmTypesGenOne.Swap memory swap
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPnlValue = IporMath.absoluteValue(pnlValue);

        if (pnlValue > 0) {
            //Buyer earns, AmmTreasury looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.liquidationDepositAmount,
                swap.collateral + absPnlValue
            );
        } else {
            //AmmTreasury earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.liquidationDepositAmount,
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

        if (wadTransferAmount + wadPayoutForLiquidator > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(wadTransferAmount, decimals);

            uint256 totalTransferAmountAssetDecimals = transferAmountAssetDecimals +
                IporMath.convertWadToAssetDecimals(wadPayoutForLiquidator, decimals);

            uint256 ammTreasuryErc20BalanceBeforeRedeem = IERC20Upgradeable(asset).balanceOf(ammTreasury);

            if (ammTreasuryErc20BalanceBeforeRedeem <= totalTransferAmountAssetDecimals) {
                AmmTypes.AmmPoolCoreModel memory model;

                model.ammStorage = ammStorage;
                model.ammTreasury = ammTreasury;
                //TODO: fix it
                //                model.assetManagement = assetManagement;

                IporTypes.AmmBalancesMemory memory balance = model.getAccruedBalance();

                StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
                    asset
                );

                int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                    IporMath.convertToWad(ammTreasuryErc20BalanceBeforeRedeem, decimals),
                    balance.vault,
                    wadTransferAmount + wadPayoutForLiquidator,
                    /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals,
                    /// example: 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                    uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
                );

                if (rebalanceAmount < 0) {
                    IAmmTreasury(ammTreasury).withdrawFromAssetManagementInternal((-rebalanceAmount).toUint256());

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

    function _getPoolConfiguration() internal view returns (AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration memory) {
        return
            AmmTypesGenOne.AmmCloseSwapServicePoolConfiguration({
                spread: spread,
                asset: asset,
                decimals: decimals,
                ammStorage: ammStorage,
                ammTreasury: ammTreasury,
                assetManagement: address(0x0),
                unwindingFeeRate: unwindingFeeRate,
                unwindingFeeTreasuryPortionRate: unwindingFeeTreasuryPortionRate,
                maxLengthOfLiquidatedSwapsPerLeg: liquidationLegLimit,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: timeBeforeMaturityAllowedToCloseSwapByCommunity,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: timeBeforeMaturityAllowedToCloseSwapByBuyer,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                minLeverage: minLeverage
            });
    }
}
