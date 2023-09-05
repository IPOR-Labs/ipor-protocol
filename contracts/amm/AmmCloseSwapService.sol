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
import "./spread/ISpreadCloseSwapService.sol";
import "../libraries/errors/IporErrors.sol";
import "../governance/AmmConfigurationManager.sol";
import "../security/OwnerManager.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/AmmLib.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/RiskManagementLogic.sol";
import "./libraries/IporSwapLogic.sol";
import "../libraries/IporContractValidator.sol";
import "./libraries/types/AmmInternalTypes.sol";

contract AmmCloseSwapService is IAmmCloseSwapService, IAmmCloseSwapLens {
    using Address for address;
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporSwapLogic for AmmTypes.Swap;
    using AmmLib for AmmTypes.AmmPoolCoreModel;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAssetManagement;

    uint256 internal immutable _usdtUnwindingFeeRate;
    uint256 internal immutable _usdtUnwindingFeeTreasuryPortionRate;
    uint256 internal immutable _usdtLiquidationLegLimit;
    uint256 internal immutable _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _usdtMinLeverage;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAmmStorage;
    address internal immutable _usdcAmmTreasury;
    address internal immutable _usdcAssetManagement;

    uint256 internal immutable _usdcUnwindingFeeRate;
    uint256 internal immutable _usdcUnwindingFeeTreasuryPortionRate;
    uint256 internal immutable _usdcLiquidationLegLimit;
    uint256 internal immutable _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _usdcMinLeverage;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAmmStorage;
    address internal immutable _daiAmmTreasury;
    address internal immutable _daiAssetManagement;

    uint256 internal immutable _daiUnwindingFeeRate;
    uint256 internal immutable _daiUnwindingFeeTreasuryPortionRate;
    uint256 internal immutable _daiLiquidationLegLimit;
    uint256 internal immutable _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity;
    uint256 internal immutable _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer;
    uint256 internal immutable _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity;
    uint256 internal immutable _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer;
    uint256 internal immutable _daiMinLeverage;

    address internal immutable _iporOracle;
    address internal immutable _iporRiskManagementOracle;
    address internal immutable _spreadRouter;

    constructor(
        AmmCloseSwapServicePoolConfiguration memory usdtPoolCfg,
        AmmCloseSwapServicePoolConfiguration memory usdcPoolCfg,
        AmmCloseSwapServicePoolConfiguration memory daiPoolCfg,
        address iporOracle,
        address iporRiskManagementOracle,
        address spreadRouter
    ) {
        _usdt = usdtPoolCfg.asset.checkAddress();
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage.checkAddress();
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury.checkAddress();
        _usdtAssetManagement = usdtPoolCfg.assetManagement.checkAddress();
        _usdtUnwindingFeeRate = usdtPoolCfg.unwindingFeeRate;
        _usdtUnwindingFeeTreasuryPortionRate = usdtPoolCfg.unwindingFeeTreasuryPortionRate;
        _usdtLiquidationLegLimit = usdtPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity = usdtPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer = usdtPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity = usdtPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer = usdtPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _usdtMinLeverage = usdtPoolCfg.minLeverage;

        _usdc = usdcPoolCfg.asset.checkAddress();
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage.checkAddress();
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury.checkAddress();
        _usdcAssetManagement = usdcPoolCfg.assetManagement.checkAddress();
        _usdcUnwindingFeeRate = usdcPoolCfg.unwindingFeeRate;
        _usdcUnwindingFeeTreasuryPortionRate = usdcPoolCfg.unwindingFeeTreasuryPortionRate;
        _usdcLiquidationLegLimit = usdcPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity = usdcPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer = usdcPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity = usdcPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer = usdcPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _usdcMinLeverage = usdcPoolCfg.minLeverage;

        _dai = daiPoolCfg.asset.checkAddress();
        _daiDecimals = daiPoolCfg.decimals;
        _daiAmmStorage = daiPoolCfg.ammStorage.checkAddress();
        _daiAmmTreasury = daiPoolCfg.ammTreasury.checkAddress();
        _daiAssetManagement = daiPoolCfg.assetManagement.checkAddress();
        _daiUnwindingFeeRate = daiPoolCfg.unwindingFeeRate;
        _daiUnwindingFeeTreasuryPortionRate = daiPoolCfg.unwindingFeeTreasuryPortionRate;
        _daiLiquidationLegLimit = daiPoolCfg.maxLengthOfLiquidatedSwapsPerLeg;
        _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity = daiPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer = daiPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity = daiPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer = daiPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _daiMinLeverage = daiPoolCfg.minLeverage;

        _iporOracle = iporOracle.checkAddress();
        _iporRiskManagementOracle = iporRiskManagementOracle.checkAddress();
        _spreadRouter = spreadRouter.checkAddress();
    }

    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view override returns (AmmCloseSwapServicePoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function getClosingSwapDetails(
        address asset,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp
    ) external view override returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails) {
        AmmCloseSwapServicePoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
            block.timestamp,
            poolCfg.asset
        );

        AmmTypes.Swap memory swap = IAmmStorage(poolCfg.ammStorage).getSwap(direction, swapId);

        require(swap.id > 0, AmmErrors.INCORRECT_SWAP_ID);

        int256 swapPnlValueToDate;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swapPnlValueToDate = swap.calculatePnlPayFixed(block.timestamp, accruedIpor.ibtPrice);
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swapPnlValueToDate = swap.calculatePnlReceiveFixed(block.timestamp, accruedIpor.ibtPrice);
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        (closingSwapDetails.closableStatus, closingSwapDetails.swapUnwindRequired) = _getClosableStatusForSwap(
            swapPnlValueToDate,
            closeTimestamp,
            swap,
            poolCfg
        );

        if (closingSwapDetails.swapUnwindRequired == true) {
            (
                closingSwapDetails.swapUnwindPnlValue,
                closingSwapDetails.swapUnwindOpeningFeeAmount,
                closingSwapDetails.swapUnwindFeeLPAmount,
                closingSwapDetails.swapUnwindFeeTreasuryAmount,
                closingSwapDetails.pnlValue
            ) = _calculateSwapUnwindWhenUnwindRequired(
                direction,
                closeTimestamp,
                swapPnlValueToDate,
                accruedIpor.indexValue,
                swap,
                poolCfg
            );
        } else {
            closingSwapDetails.pnlValue = swapPnlValueToDate;
        }
    }

    function closeSwapsUsdt(
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
            _getPoolConfiguration(_usdt)
        );
    }

    function closeSwapsUsdc(
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
            _getPoolConfiguration(_usdc)
        );
    }

    function closeSwapsDai(
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
            _getPoolConfiguration(_dai)
        );
    }

    function emergencyCloseSwapsUsdt(
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
            _getPoolConfiguration(_usdt)
        );
    }

    function emergencyCloseSwapsUsdc(
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
            _getPoolConfiguration(_usdc)
        );
    }

    function emergencyCloseSwapsDai(
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
            _getPoolConfiguration(_dai)
        );
    }

    function _getPoolConfiguration(address asset) internal view returns (AmmCloseSwapServicePoolConfiguration memory) {
        if (asset == _usdt) {
            return
                AmmCloseSwapServicePoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    assetManagement: _usdtAssetManagement,
                    unwindingFeeRate: _usdtUnwindingFeeRate,
                    unwindingFeeTreasuryPortionRate: _usdtUnwindingFeeTreasuryPortionRate,
                    maxLengthOfLiquidatedSwapsPerLeg: _usdtLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _usdtMinLeverage
                });
        } else if (asset == _usdc) {
            return
                AmmCloseSwapServicePoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    assetManagement: _usdcAssetManagement,
                    unwindingFeeRate: _usdcUnwindingFeeRate,
                    unwindingFeeTreasuryPortionRate: _usdcUnwindingFeeTreasuryPortionRate,
                    maxLengthOfLiquidatedSwapsPerLeg: _usdcLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _usdcMinLeverage
                });
        } else if (asset == _dai) {
            return
                AmmCloseSwapServicePoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    assetManagement: _daiAssetManagement,
                    unwindingFeeRate: _daiUnwindingFeeRate,
                    unwindingFeeTreasuryPortionRate: _daiUnwindingFeeTreasuryPortionRate,
                    maxLengthOfLiquidatedSwapsPerLeg: _daiLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _daiMinLeverage
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }

    function _closeSwaps(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
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
        AmmCloseSwapServicePoolConfiguration memory poolCfg
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

        ISpreadCloseSwapService(_spreadRouter).updateTimeWeightedNotionalOnClose(
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
            emit SwapUnwind(
                poolCfg.asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit CloseSwap(swap.id, poolCfg.asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapReceiveFixed(
        address beneficiary,
        uint256 indexValue,
        uint256 ibtPrice,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
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

        ISpreadCloseSwapService(_spreadRouter).updateTimeWeightedNotionalOnClose(
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
            emit SwapUnwind(
                poolCfg.asset,
                swap.id,
                swapPnlValueToDate,
                pnlValueStruct.swapUnwindAmount,
                pnlValueStruct.swapUnwindFeeLPAmount,
                pnlValueStruct.swapUnwindFeeTreasuryAmount
            );
        }

        emit CloseSwap(swap.id, poolCfg.asset, timestamp, beneficiary, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPerLeg(
        address beneficiary,
        AmmTypes.SwapDirection direction,
        uint256[] memory swapIds,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 swapIdsLength = swapIds.length;
        require(
            swapIdsLength <= poolCfg.maxLengthOfLiquidatedSwapsPerLeg,
            AmmErrors.MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED
        );

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIdsLength);
        AmmTypes.Swap memory swap;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
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
        AmmCloseSwapServicePoolConfiguration memory poolCfg
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
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (AmmInternalTypes.PnlValueStruct memory pnlValueStruct) {
        AmmTypes.SwapClosableStatus closableStatus;

        (closableStatus, pnlValueStruct.swapUnwindRequired) = _getClosableStatusForSwap(
            swapPnlValueToDate,
            closeTimestamp,
            swap,
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
            ) = _calculateSwapUnwindWhenUnwindRequired(
                direction,
                closeTimestamp,
                swapPnlValueToDate,
                indexValue,
                swap,
                poolCfg
            );
        } else {
            pnlValueStruct.pnlValue = swapPnlValueToDate;
        }
    }

    /// @notice Calculate swap unwind when unwind is required.
    /// @param direction swap direction
    /// @param closeTimestamp close timestamp
    /// @param swapPnlValueToDate swap PnL to a specific date (in particular case to current date)
    /// @param indexValue index value
    /// @param swap swap struct
    /// @param poolCfg pool configuration
    /// @return swapUnwindPnlValue swap unwind PnL value
    /// @return swapUnwindFeeAmount swap unwind opening fee amount
    /// @return swapUnwindFeeLPAmount swap unwind opening fee LP amount
    /// @return swapUnwindFeeTreasuryAmount swap unwind opening fee treasury amount
    /// @return swapPnlValue swap PnL value includes swap PnL to date, swap unwind PnL value, this value NOT INCLUDE swap unwind fee amount.
    function _calculateSwapUnwindWhenUnwindRequired(
        AmmTypes.SwapDirection direction,
        uint256 closeTimestamp,
        int256 swapPnlValueToDate,
        uint256 indexValue,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
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
        uint256 oppositeDirection;

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            oppositeDirection = 1;
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            oppositeDirection = 0;
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }

        uint256 oppositeLegFixedRate = RiskManagementLogic.calculateOfferedRate(
            oppositeDirection,
            swap.tenor,
            swap.notional,
            RiskManagementLogic.SpreadOfferedRateContext({
                asset: poolCfg.asset,
                ammStorage: poolCfg.ammStorage,
                iporRiskManagementOracle: _iporRiskManagementOracle,
                spreadRouter: _spreadRouter,
                minLeverage: poolCfg.minLeverage,
                indexValue: indexValue
            })
        );

        /// @dev Not allow to have swap unwind pnl absolute value larger than swap collateral.
        swapUnwindPnlValue = IporSwapLogic.normalizePnlValue(
            swap.collateral,
            swap.calculateSwapUnwindPnlValue(direction, closeTimestamp, oppositeLegFixedRate)
        );

        swapPnlValue = IporSwapLogic.normalizePnlValue(swap.collateral, swapPnlValueToDate + swapUnwindPnlValue);

        /// @dev swap unwind fee amount is independent of the swap unwind pnl value, takes into consideration notional.
        swapUnwindFeeAmount = swap.calculateSwapUnwindOpeningFeeAmount(closeTimestamp, poolCfg.unwindingFeeRate);

        require(
            swap.collateral.toInt256() + swapPnlValue > swapUnwindFeeAmount.toInt256(),
            AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP
        );

        (swapUnwindFeeLPAmount, swapUnwindFeeTreasuryAmount) = IporSwapLogic.splitOpeningFeeAmount(
            swapUnwindFeeAmount,
            poolCfg.unwindingFeeTreasuryPortionRate
        );

        swapPnlValue = swapPnlValueToDate + swapUnwindPnlValue;
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
        AmmCloseSwapServicePoolConfiguration memory poolCfg
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

    /// @notice Check closable status for Swap given as a parameter.
    /// @param swap The swap to be checked
    /// @param swapPnlValueToDate The pnl of the swap on a given date
    /// @param closeTimestamp The timestamp of closing
    /// @return closableStatus Closable status for Swap.
    /// @return swapUnwindRequired True if swap unwind is required.
    function _getClosableStatusForSwap(
        int256 swapPnlValueToDate,
        uint256 closeTimestamp,
        AmmTypes.Swap memory swap,
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal view returns (AmmTypes.SwapClosableStatus, bool) {
        if (swap.state != IporTypes.SwapState.ACTIVE) {
            return (AmmTypes.SwapClosableStatus.SWAP_ALREADY_CLOSED, false);
        }

        address msgSender = msg.sender;

        if (msgSender != OwnerManager.getOwner()) {
            uint256 absPnlValue = IporMath.absoluteValue(swapPnlValueToDate);

            uint256 minPnlValueToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                swap.collateral,
                poolCfg.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            uint256 swapEndTimestamp = swap.getSwapEndTimestamp();

            if (closeTimestamp >= swapEndTimestamp) {
                if (absPnlValue < minPnlValueToCloseBeforeMaturityByCommunity || absPnlValue == swap.collateral) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(poolCfg.asset, msgSender) != true &&
                        msgSender != swap.buyer
                    ) {
                        return (AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE, false);
                    }
                }
            } else {
                uint256 minPnlValueToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    swap.collateral,
                    poolCfg.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPnlValue >= minPnlValueToCloseBeforeMaturityByBuyer &&
                        absPnlValue < minPnlValueToCloseBeforeMaturityByCommunity) || absPnlValue == swap.collateral
                ) {
                    if (
                        AmmConfigurationManager.isSwapLiquidator(poolCfg.asset, msgSender) != true &&
                        msgSender != swap.buyer
                    ) {
                        return (AmmTypes.SwapClosableStatus.SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE, false);
                    }
                }

                if (absPnlValue < minPnlValueToCloseBeforeMaturityByBuyer) {
                    if (msgSender == swap.buyer) {
                        if (swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer > closeTimestamp) {
                            return (AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE, true);
                        }
                    } else {
                        if (
                            swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity > closeTimestamp
                        ) {
                            return (
                                AmmTypes.SwapClosableStatus.SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY,
                                false
                            );
                        }
                    }
                }
            }
        }

        return (AmmTypes.SwapClosableStatus.SWAP_IS_CLOSABLE, false);
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
        AmmCloseSwapServicePoolConfiguration memory poolCfg
    ) internal returns (uint256 wadTransferredToBuyer, uint256 wadPayoutForLiquidator) {
        if (beneficiary == buyer) {
            wadTransferAmount = wadTransferAmount + wadLiquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from AmmTreasury to Liquidator address (beneficiary),
            // transfer to be made outside this function, to avoid multiple transfers
            wadPayoutForLiquidator = wadLiquidationDepositAmount;
        }

        if (wadTransferAmount > 0) {
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
                    /// @dev 1e14 explanation: ammTreasuryAndAssetManagementRatio represents percentage in 2 decimals, example 45% = 4500, so to achieve number in 18 decimals we need to multiply by 1e14
                    uint256(ammPoolsParamsCfg.ammTreasuryAndAssetManagementRatio) * 1e14
                );

                if (rebalanceAmount < 0) {
                    IAmmTreasury(poolCfg.ammTreasury).withdrawFromAssetManagementInternal(
                        (-rebalanceAmount).toUint256()
                    );
                }
            }

            IERC20Upgradeable(poolCfg.asset).safeTransferFrom(poolCfg.ammTreasury, buyer, transferAmountAssetDecimals);

            wadTransferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, poolCfg.decimals);
        }
    }
}
