// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmStorageStEth.sol";
import "../interfaces/IAmmCloseSwapLensStEth.sol";
import "../interfaces/IAmmCloseSwapService.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/AmmLib.sol";
import "../governance/AmmConfigurationManager.sol";
import "../security/OwnerManager.sol";
import "../amm/libraries/IporSwapLogic.sol";
import "../amm/libraries/types/AmmInternalTypes.sol";
import "../libraries/SwapEvents.sol";
import "../amm/spread/ISpreadCloseSwapService.sol";
import "../interfaces/IAmmCloseSwapServiceStEth.sol";
import "../interfaces/IAmmCloseSwapLens.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmCloseSwapServiceStEth is IAmmCloseSwapServiceStEth, IAmmCloseSwapLensStEth {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporSwapLogic for AmmTypes.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    /// @dev stETH address
    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _ammTreasury;

    uint256 internal immutable _unwindingFeeRate;
    uint256 internal immutable _unwindingFeeTreasuryPortionRate;
    uint256 internal immutable _liquidationLegLimit;
    uint256 internal immutable _timeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _timeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _minLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _minLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _minLeverage;

    address public immutable iporOracle;
    address public immutable iporRiskManagementOracle;
    address public immutable spreadRouter;

    constructor(
        AmmTypes.CloseSwapAmmPoolConfiguration memory stEthPoolCfg,
        address iporOracleInput,
        address iporRiskManagementOracleInput,
        address spreadRouterInput
    ) {
        _asset = stEthPoolCfg.asset.checkAddress();
        _decimals = stEthPoolCfg.decimals;
        _ammStorage = stEthPoolCfg.ammStorage.checkAddress();
        _ammTreasury = stEthPoolCfg.ammTreasury.checkAddress();
        _unwindingFeeRate = stEthPoolCfg.unwindingFeeRate;
        _unwindingFeeTreasuryPortionRate = stEthPoolCfg.unwindingFeeTreasuryPortionRate;
        _liquidationLegLimit = stEthPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _timeBeforeMaturityAllowedToCloseSwapByCommunity = stEthPoolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _timeBeforeMaturityAllowedToCloseSwapByBuyer = stEthPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _minLiquidationThresholdToCloseBeforeMaturityByCommunity = stEthPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _minLiquidationThresholdToCloseBeforeMaturityByBuyer = stEthPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _minLeverage = stEthPoolCfg.minLeverage;

        iporOracle = iporOracleInput.checkAddress();
        iporRiskManagementOracle = iporRiskManagementOracleInput.checkAddress();
        spreadRouter = spreadRouterInput.checkAddress();
    }

    function getAmmCloseSwapServicePoolConfigurationStEth()
        external
        view
        override
        returns (AmmTypes.CloseSwapAmmPoolConfiguration memory)
    {
        return _getPoolConfiguration();
    }

    function getClosingSwapDetailsStEth(
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg = _getPoolConfiguration();

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypes.Swap memory swap = IAmmStorageStEth(_ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swapPnlValueToDate = swap.calculatePnlPayFixed(block.timestamp, accruedIpor.ibtPrice);
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swapPnlValueToDate = swap.calculatePnlReceiveFixed(block.timestamp, accruedIpor.ibtPrice);
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = swap.getClosableStatusForSwap(
            account,
            swapPnlValueToDate,
            closeTimestamp,
            poolCfg
        );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = swap.calculateSwapUnwindWhenUnwindRequired(
                direction,
                closeTimestamp,
                swapPnlValueToDate,
                accruedIpor.indexValue,
                poolCfg
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }

    function closeSwapsStEth(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            beneficiary,
            payFixedSwapIds,
            receiveFixedSwapIds,
            _getPoolConfiguration()
        );
    }

    function emergencyCloseSwapsStEth(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    )
        external
        override
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            msg.sender,
            payFixedSwapIds,
            receiveFixedSwapIds,
            _getPoolConfiguration()
        );
    }

    function _closeSwaps(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
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
            poolCfg
        );

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsPerLeg(
            beneficiary,
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            receiveFixedSwapIds,
            poolCfg
        );

        _transferLiquidationDepositAmount(
            beneficiary,
            payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed,
            poolCfg
        );
    }

    function _closeSwapPayFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypes.Swap memory swap,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = swap.calculatePnlPayFixed(timestamp, ibtPrice);

        AmmInternalTypes.PnlValueStruct memory pnlValueStruct = _preparePnlValueStructForClose(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            poolCfg
        );

        ISpreadCloseSwapService(spreadRouter).updateTimeWeightedNotionalOnClose(
            poolCfg.asset,
            0,
            swap.tenor,
            swap.notional,
            IAmmStorageStEth(poolCfg.ammStorage).updateStorageWhenCloseSwapPayFixedInternal(
                swap,
                pnlValueStruct.pnlValue,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                timestamp
            ),
            poolCfg.ammStorage
        );

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPnlValue(
            beneficiary,
            pnlValueStruct.pnlValue -
                pnlValueStruct.swapUnwindFeeLPAmount.toInt256() -
                pnlValueStruct.swapUnwindFeeTreasuryAmount.toInt256(),
            swap,
            poolCfg
        );

        if (pnlValueStruct.swapUnwindRequired) {
            emit SwapEvents.SwapUnwind(
                poolCfg.asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit SwapEvents.CloseSwap(swap.id, poolCfg.asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapReceiveFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypes.Swap memory swap,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 timestamp = block.timestamp;
        int256 swapPnlValueToDate = swap.calculatePnlReceiveFixed(timestamp, ibtPrice);

        AmmInternalTypes.PnlValueStruct memory pnlValueStruct = _preparePnlValueStructForClose(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            poolCfg
        );

        ISpreadCloseSwapService(spreadRouter).updateTimeWeightedNotionalOnClose(
            poolCfg.asset,
            1,
            swap.tenor,
            swap.notional,
            IAmmStorageStEth(poolCfg.ammStorage).updateStorageWhenCloseSwapReceiveFixedInternal(
                swap,
                pnlValueStruct.pnlValue,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                timestamp
            ),
            poolCfg.ammStorage
        );

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPnlValue(
            beneficiary,
            pnlValueStruct.pnlValue -
                pnlValueStruct.swapUnwindFeeLPAmount.toInt256() -
                pnlValueStruct.swapUnwindFeeTreasuryAmount.toInt256(),
            swap,
            poolCfg
        );

        if (pnlValueStruct.swapUnwindRequired) {
            emit SwapEvents.SwapUnwind(
                poolCfg.asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit SwapEvents.CloseSwap(swap.id, poolCfg.asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPerLeg(
        address beneficiary,
        AmmTypes.SwapDirection direction,
        uint256[] memory swapIds,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 swapIdsLength = swapIds.length;
        require(
            swapIdsLength <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIdsLength);
        AmmTypes.Swap memory swap;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );
        uint256 swapId;

        for (uint256 i; i != swapIdsLength; ) {
            swapId = swapIds[i];
            require(swapId > 0, AmmErrors.INCORRECT_SWAP_ID);

            swap = IAmmStorageStEth(poolCfg.ammStorage).getSwap(direction, swapId);

            if (swap.state == IporTypes.SwapState.ACTIVE) {
                if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
                    payoutForLiquidator += _closeSwapPayFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        poolCfg
                    );
                } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
                    payoutForLiquidator += _closeSwapReceiveFixed(
                        beneficiary,
                        accruedIpor.indexValue,
                        accruedIpor.ibtPrice,
                        swap,
                        poolCfg
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
    function _transferLiquidationDepositAmount(
        address liquidator,
        uint256 liquidationDepositAmount,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal {
        if (liquidationDepositAmount > 0) {
            IERC20Upgradeable(poolCfg.asset).safeTransferFrom(
                poolCfg.ammTreasury,
                liquidator,
                IporMath.convertWadToAssetDecimals(liquidationDepositAmount, poolCfg.decimals)
            );
        }
    }

    function _preparePnlValueStructForClose(
        AmmTypes.SwapDirection direction,
        uint256 closeTimestamp,
        int256 swapPnlValueToDate,
        uint256 indexValue,
        AmmTypes.Swap memory swap,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal view returns (AmmInternalTypes.PnlValueStruct memory pnlValueStruct) {
        AmmTypes.SwapClosableStatus closableStatus;

        (closableStatus, pnlValueStruct.swapUnwindRequired) = swap.getClosableStatusForSwap(
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
            ) = swap.calculateSwapUnwindWhenUnwindRequired(
                direction,
                closeTimestamp,
                swapPnlValueToDate,
                indexValue,
                poolCfg
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
     * @param poolCfg - Pool configuration
     **/
    function _transferTokensBasedOnPnlValue(
        address beneficiary,
        int256 pnlValue,
        AmmTypes.Swap memory swap,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPnlValue = IporMath.absoluteValue(pnlValue);

        if (pnlValue > 0) {
            //Buyer earns, AmmTreasury looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.liquidationDepositAmount,
                swap.collateral + absPnlValue,
                poolCfg
            );
        } else {
            //AmmTreasury earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                beneficiary,
                swap.buyer,
                swap.liquidationDepositAmount,
                swap.collateral - absPnlValue,
                poolCfg
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
    /// @param poolCfg Pool configuration
    /// @return wadTransferredToBuyer Final value transferred to buyer, containing collateral and pnl value and if buyer is beneficiary, liquidation deposit amount
    /// @return wadPayoutForLiquidator Final value transferred to liquidator, if liquidator is beneficiary then value is zero
    /// @dev If beneficiary is buyer, then liquidation deposit amount is added to transfer amount.
    /// @dev Input amounts and returned values are represented in 18 decimals.
    function _transferDerivativeAmount(
        address beneficiary,
        address buyer,
        uint256 wadLiquidationDepositAmount,
        uint256 wadTransferAmount,
        AmmTypes.CloseSwapAmmPoolConfiguration memory poolCfg
    ) internal returns (uint256 wadTransferredToBuyer, uint256 wadPayoutForLiquidator) {
        if (beneficiary == buyer) {
            wadTransferAmount = wadTransferAmount + wadLiquidationDepositAmount;
        } else {
            /// @dev transfer liquidation deposit amount from AmmTreasury to Liquidator address (beneficiary),
            /// transfer to be made outside this function, to avoid multiple transfers
            wadPayoutForLiquidator = wadLiquidationDepositAmount;
        }

        if (wadTransferAmount + wadPayoutForLiquidator > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
                wadTransferAmount,
                poolCfg.decimals
            );

            uint256 totalTransferAmountAssetDecimals = transferAmountAssetDecimals +
                IporMath.convertWadToAssetDecimals(wadPayoutForLiquidator, poolCfg.decimals);

            uint256 ammTreasuryErc20BalanceBeforeRedeem = IERC20Upgradeable(poolCfg.asset).balanceOf(
                poolCfg.ammTreasury
            );

            if (ammTreasuryErc20BalanceBeforeRedeem <= totalTransferAmountAssetDecimals) {
                AmmTypes.AmmPoolCoreModel memory model;

                model.ammStorage = poolCfg.ammStorage;
                model.ammTreasury = poolCfg.ammTreasury;
                model.assetManagement = poolCfg.assetManagement;

                IporTypes.AmmBalancesMemory memory balance = model.getAccruedBalance();

                StorageLib.AmmPoolsParamsValue memory ammPoolsParamsCfg = AmmConfigurationManager.getAmmPoolsParams(
                    poolCfg.asset
                );

                int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                    IporMath.convertToWad(ammTreasuryErc20BalanceBeforeRedeem, poolCfg.decimals),
                    balance.vault,
                    wadTransferAmount + wadPayoutForLiquidator,
                    /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals,
                    /// example: 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                    uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
                );

                if (rebalanceAmount < 0) {
                    IAmmTreasury(poolCfg.ammTreasury).withdrawFromAssetManagementInternal(
                        (-rebalanceAmount).toUint256()
                    );

                    /// @dev check if withdraw from asset management is enough to cover transfer amount
                    /// @dev possible case when strategies are paused and assets are temporary locked
                    require(
                        totalTransferAmountAssetDecimals <=
                            IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury),
                        AmmErrors.ASSET_MANAGEMENT_WITHDRAW_NOT_ENOUGH
                    );
                }
            }

            IERC20Upgradeable(poolCfg.asset).safeTransferFrom(poolCfg.ammTreasury, buyer, transferAmountAssetDecimals);

            wadTransferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, poolCfg.decimals);
        }
    }

    function _getPoolConfiguration() internal view returns (AmmTypes.CloseSwapAmmPoolConfiguration memory) {
        return
            AmmTypes.CloseSwapAmmPoolConfiguration({
                spreadRouter: spreadRouter,
                iporRiskManagementOracle: iporRiskManagementOracle,
                asset: _asset,
                decimals: _decimals,
                ammStorage: _ammStorage,
                ammTreasury: _ammTreasury,
                assetManagement: address(0x0),
                unwindingFeeRate: _unwindingFeeRate,
                unwindingFeeTreasuryPortionRate: _unwindingFeeTreasuryPortionRate,
                maxLengthOfLiquidatedSwapsPerLeg: _liquidationLegLimit,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: _timeBeforeMaturityAllowedToCloseSwapByCommunity,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: _timeBeforeMaturityAllowedToCloseSwapByBuyer,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: _minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: _minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                minLeverage: _minLeverage
            });
    }
}
