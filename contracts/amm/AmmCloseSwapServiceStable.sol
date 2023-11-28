// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmTreasury.sol";
import "../interfaces/IAmmCloseSwapLens.sol";
import "../interfaces/IAmmCloseSwapService.sol";
import "../base/amm/libraries/SwapEventsBaseV1.sol";
import "../interfaces/IAmmCloseSwapServiceUsdt.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/AmmLib.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/RiskManagementLogic.sol";
import "../libraries/RiskIndicatorsValidatorLib.sol";
import "../governance/AmmConfigurationManager.sol";
import "../security/OwnerManager.sol";
import "../base/amm/libraries/SwapLogicBaseV1.sol";
import "../base/types/AmmTypesBaseV1.sol";
import "../base/amm/libraries/SwapCloseLogicLibBaseV1.sol";
import "./libraries/types/AmmInternalTypes.sol";
import "./spread/ISpreadCloseSwapService.sol";
import "./libraries/SwapCloseLogicLib.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
abstract contract AmmCloseSwapServiceStable is IAmmCloseSwapService {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    address internal immutable _asset;
    uint256 internal immutable _decimals;
    address internal immutable _ammStorage;
    address internal immutable _ammTreasury;
    address internal immutable _assetManagement;

    uint256 internal immutable _unwindingFeeRate;
    uint256 internal immutable _unwindingFeeTreasuryPortionRate;
    uint256 internal immutable _liquidationLegLimit;
    uint256 internal immutable _timeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _timeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _minLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _minLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _minLeverage;
    uint256 internal immutable _timeAfterOpenAllowedToCloseSwapWithUnwinding;

    address public immutable iporOracle;
    address public immutable messageSigner;
    address public immutable spreadRouter;

    constructor(
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput
    ) {
        _asset = poolCfg.asset.checkAddress();
        _decimals = poolCfg.decimals;
        _ammStorage = poolCfg.ammStorage.checkAddress();
        _ammTreasury = poolCfg.ammTreasury.checkAddress();
        _assetManagement = poolCfg.assetManagement.checkAddress();
        _unwindingFeeRate = poolCfg.unwindingFeeRate;
        _unwindingFeeTreasuryPortionRate = poolCfg.unwindingFeeTreasuryPortionRate;
        _liquidationLegLimit = poolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _timeBeforeMaturityAllowedToCloseSwapByCommunity = poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _timeBeforeMaturityAllowedToCloseSwapByBuyer = poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _minLiquidationThresholdToCloseBeforeMaturityByCommunity = poolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _minLiquidationThresholdToCloseBeforeMaturityByBuyer = poolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _minLeverage = poolCfg.minLeverage;
        _timeAfterOpenAllowedToCloseSwapWithUnwinding = poolCfg.timeAfterOpenAllowedToCloseSwapWithUnwinding;

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
        spreadRouter = poolCfg.spread.checkAddress();
    }

    function getPoolConfiguration()
        external
        view
        override
        returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory)
    {
        return _getPoolConfiguration();
    }

    function _getPoolConfiguration()
        internal
        view
        returns (IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory)
    {
        return
            IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: _asset,
                decimals: _decimals,
                ammStorage: _ammStorage,
                ammTreasury: _ammTreasury,
                assetManagement: _assetManagement,
                spread: spreadRouter,
                unwindingFeeRate: _unwindingFeeRate,
                unwindingFeeTreasuryPortionRate: _unwindingFeeTreasuryPortionRate,
                maxLengthOfLiquidatedSwapsPerLeg: _liquidationLegLimit,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: _timeBeforeMaturityAllowedToCloseSwapByCommunity,
                timeBeforeMaturityAllowedToCloseSwapByBuyer: _timeBeforeMaturityAllowedToCloseSwapByBuyer,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: _minLiquidationThresholdToCloseBeforeMaturityByCommunity,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: _minLiquidationThresholdToCloseBeforeMaturityByBuyer,
                minLeverage: _minLeverage,
                timeAfterOpenAllowedToCloseSwapWithUnwinding: _timeAfterOpenAllowedToCloseSwapWithUnwinding
            });
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
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration();

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
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
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
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            poolCfg,
            riskIndicatorsInput
        );

        ISpreadCloseSwapService(spreadRouter).updateTimeWeightedNotionalOnClose(
            poolCfg.asset,
            0,
            swap.tenor,
            swap.notional,
            IAmmStorage(poolCfg.ammStorage).updateStorageWhenCloseSwapPayFixedInternal(
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
            emit SwapEventsBaseV1.SwapUnwind(
                poolCfg.asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit SwapEventsBaseV1.CloseSwap(
            swap.id,
            poolCfg.asset,
            timestamp,
            beneficiary,
            transferredToBuyer,
            payoutForLiquidator
        );
    }

    function _closeSwapReceiveFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypes.Swap memory swap,
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
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
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            timestamp,
            swapPnlValueToDate,
            indexValue,
            swap,
            poolCfg,
            riskIndicatorsInput
        );

        ISpreadCloseSwapService(spreadRouter).updateTimeWeightedNotionalOnClose(
            poolCfg.asset,
            1,
            swap.tenor,
            swap.notional,
            IAmmStorage(poolCfg.ammStorage).updateStorageWhenCloseSwapReceiveFixedInternal(
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
            emit SwapEventsBaseV1.SwapUnwind(
                poolCfg.asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit SwapEventsBaseV1.CloseSwap(
            swap.id,
            poolCfg.asset,
            timestamp,
            beneficiary,
            transferredToBuyer,
            payoutForLiquidator
        );
    }

    function _closeSwapsPerLeg(
        address beneficiary,
        AmmTypes.SwapDirection direction,
        uint256[] memory swapIds,
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
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

            swap = IAmmStorage(poolCfg.ammStorage).getSwap(direction, swapId);

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
    function _transferLiquidationDepositAmount(
        address liquidator,
        uint256 liquidationDepositAmount,
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg
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
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) internal view returns (AmmInternalTypes.PnlValueStruct memory pnlValueStruct) {
        AmmTypes.SwapClosableStatus closableStatus;

        (closableStatus, pnlValueStruct.swapUnwindRequired) = SwapCloseLogicLibBaseV1.getClosableStatusForSwap(
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

        SwapCloseLogicLibBaseV1.validateAllowanceToCloseSwap(closableStatus);

        if (pnlValueStruct.swapUnwindRequired == true) {
            (
                pnlValueStruct.swapUnwindAmount,
                ,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount,
                pnlValueStruct.pnlValue
            ) = SwapCloseLogicLib.calculateSwapUnwindWhenUnwindRequired(
                AmmTypes.UnwindParams({
                    messageSigner: messageSigner,
                    spreadRouter: spreadRouter,
                    ammStorage: poolCfg.ammStorage,
                    ammTreasury: poolCfg.ammTreasury,
                    direction: direction,
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
     * @param poolCfg - Pool configuration
     **/
    function _transferTokensBasedOnPnlValue(
        address beneficiary,
        int256 pnlValue,
        AmmTypes.Swap memory swap,
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg
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
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration memory poolCfg
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
}
