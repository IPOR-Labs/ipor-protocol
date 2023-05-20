// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../libraries/math/IporMath.sol";
import "../libraries/errors/IporErrors.sol";
import "../security/OwnerManager.sol";
import "../libraries/AmmLib.sol";
import "../libraries/AssetManagementLogic.sol";
import "../libraries/RiskManagementLogic.sol";
import "../amm/libraries/IporSwapLogic.sol";
import "../governance/AmmConfigurationManager.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/MiltonTypes.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMiltonInternal.sol";
import "../interfaces/IAmmCloseSwapService.sol";

contract AmmCloseSwapService is IAmmCloseSwapService {
    using Address for address;
    using SafeCast for uint256;
    using SafeCast for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporSwapLogic for IporTypes.IporSwapMemory;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAmmStorage;
    address internal immutable _usdtAmmTreasury;
    address internal immutable _usdtAssetManagement;

    uint256 internal immutable _usdtOpeningFeeRate;
    uint256 internal immutable _usdtOpeningFeeRateForSwapUnwind;
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

    uint256 internal immutable _usdcOpeningFeeRate;
    uint256 internal immutable _usdcOpeningFeeRateForSwapUnwind;
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

    uint256 internal immutable _daiOpeningFeeRate;
    uint256 internal immutable _daiOpeningFeeRateForSwapUnwind;
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
        PoolConfiguration memory usdtPoolCfg,
        PoolConfiguration memory usdcPoolCfg,
        PoolConfiguration memory daiPoolCfg,
        address iporOracle,
        address iporRiskManagementOracle,
        address spreadRouter
    ) {
        require(usdtPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool asset"));
        require(usdtPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammStorage"));
        require(
            usdtPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDT pool ammTreasury")
        );

        require(usdcPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool asset"));
        require(usdcPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammStorage"));
        require(
            usdcPoolCfg.ammTreasury != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " USDC pool ammTreasury")
        );

        require(daiPoolCfg.asset != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool asset"));
        require(daiPoolCfg.ammStorage != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammStorage"));
        require(daiPoolCfg.ammTreasury != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI pool ammTreasury"));

        require(iporOracle != address(0), string.concat(IporErrors.WRONG_ADDRESS, " iporOracle"));
        require(
            iporRiskManagementOracle != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " iporRiskManagementOracle")
        );
        require(spreadRouter != address(0), string.concat(IporErrors.WRONG_ADDRESS, " spreadRouter"));

        _usdt = usdtPoolCfg.asset;
        _usdtDecimals = usdtPoolCfg.decimals;
        _usdtAmmStorage = usdtPoolCfg.ammStorage;
        _usdtAmmTreasury = usdtPoolCfg.ammTreasury;
        _usdtAssetManagement = usdtPoolCfg.assetManagement;
        _usdtOpeningFeeRate = usdtPoolCfg.openingFeeRate;
        _usdtOpeningFeeRateForSwapUnwind = usdtPoolCfg.openingFeeRateForSwapUnwind;
        _usdtLiquidationLegLimit = usdtPoolCfg.liquidationLegLimit;
        _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity = usdtPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer = usdtPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity = usdtPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer = usdtPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _usdtMinLeverage = usdtPoolCfg.minLeverage;

        _usdc = usdcPoolCfg.asset;
        _usdcDecimals = usdcPoolCfg.decimals;
        _usdcAmmStorage = usdcPoolCfg.ammStorage;
        _usdcAmmTreasury = usdcPoolCfg.ammTreasury;
        _usdcAssetManagement = usdcPoolCfg.assetManagement;
        _usdcOpeningFeeRate = usdcPoolCfg.openingFeeRate;
        _usdcOpeningFeeRateForSwapUnwind = usdcPoolCfg.openingFeeRateForSwapUnwind;
        _usdcLiquidationLegLimit = usdcPoolCfg.liquidationLegLimit;
        _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity = usdcPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer = usdcPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity = usdcPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer = usdcPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _usdcMinLeverage = usdcPoolCfg.minLeverage;

        _dai = daiPoolCfg.asset;
        _daiDecimals = daiPoolCfg.decimals;
        _daiAmmStorage = daiPoolCfg.ammStorage;
        _daiAmmTreasury = daiPoolCfg.ammTreasury;
        _daiAssetManagement = daiPoolCfg.assetManagement;
        _daiOpeningFeeRate = daiPoolCfg.openingFeeRate;
        _daiOpeningFeeRateForSwapUnwind = daiPoolCfg.openingFeeRateForSwapUnwind;
        _daiLiquidationLegLimit = daiPoolCfg.liquidationLegLimit;
        _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity = daiPoolCfg
            .timeBeforeMaturityAllowedToCloseSwapByCommunity;
        _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer = daiPoolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer;
        _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity = daiPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer = daiPoolCfg
            .minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        _daiMinLeverage = daiPoolCfg.minLeverage;

        _iporOracle = iporOracle;
        _iporRiskManagementOracle = iporRiskManagementOracle;
        _spreadRouter = spreadRouter;
    }

    function closeSwapPayFixed(
        address asset,
        address onBehalfOf,
        uint256 swapId
    ) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(onBehalfOf, swapId, _getPoolConfiguration(asset));
    }

    function closeSwapReceiveFixed(
        address asset,
        address onBehalfOf,
        uint256 swapId
    ) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(onBehalfOf, swapId, _getPoolConfiguration(asset));
    }

    function closeSwaps(
        address asset,
        address onBehalfOf,
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
            onBehalfOf,
            payFixedSwapIds,
            receiveFixedSwapIds,
            _getPoolConfiguration(asset)
        );
    }

    function emergencyCloseSwapPayFixed(address asset, uint256 swapId) external override {
        _closeSwapPayFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(asset));
    }

    function emergencyCloseSwapReceiveFixed(address asset, uint256 swapId) external override {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(msg.sender, swapId, _getPoolConfiguration(asset));
    }

    function emergencyCloseSwapsPayFixed(address asset, uint256[] memory swapIds)
        external
        override
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(asset, msg.sender, swapIds);
    }

    function emergencyCloseSwapsReceiveFixed(address asset, uint256[] memory swapIds)
        external
        override
        returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(asset, msg.sender, swapIds);
    }

    function getPoolConfiguration(address asset) external view override returns (PoolConfiguration memory) {
        return _getPoolConfiguration(asset);
    }

    function _getPoolConfiguration(address asset) internal view returns (PoolConfiguration memory) {
        if (asset == _usdt) {
            return
                PoolConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    ammStorage: _usdtAmmStorage,
                    ammTreasury: _usdtAmmTreasury,
                    assetManagement: _usdtAssetManagement,
                    openingFeeRate: _usdtOpeningFeeRate,
                    openingFeeRateForSwapUnwind: _usdtOpeningFeeRateForSwapUnwind,
                    liquidationLegLimit: _usdtLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _usdtTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _usdtTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _usdtMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _usdtMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _usdtMinLeverage
                });
        } else if (asset == _usdc) {
            return
                PoolConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    ammStorage: _usdcAmmStorage,
                    ammTreasury: _usdcAmmTreasury,
                    assetManagement: _usdcAssetManagement,
                    openingFeeRate: _usdcOpeningFeeRate,
                    openingFeeRateForSwapUnwind: _usdcOpeningFeeRateForSwapUnwind,
                    liquidationLegLimit: _usdcLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _usdcTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _usdcTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _usdcMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _usdcMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _usdcMinLeverage
                });
        } else if (asset == _dai) {
            return
                PoolConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    ammStorage: _daiAmmStorage,
                    ammTreasury: _daiAmmTreasury,
                    assetManagement: _daiAssetManagement,
                    openingFeeRate: _daiOpeningFeeRate,
                    openingFeeRateForSwapUnwind: _daiOpeningFeeRateForSwapUnwind,
                    liquidationLegLimit: _daiLiquidationLegLimit,
                    timeBeforeMaturityAllowedToCloseSwapByCommunity: _daiTimeBeforeMaturityAllowedToCloseSwapByCommunity,
                    timeBeforeMaturityAllowedToCloseSwapByBuyer: _daiTimeBeforeMaturityAllowedToCloseSwapByBuyer,
                    minLiquidationThresholdToCloseBeforeMaturityByCommunity: _daiMinLiquidationThresholdToCloseBeforeMaturityByCommunity,
                    minLiquidationThresholdToCloseBeforeMaturityByBuyer: _daiMinLiquidationThresholdToCloseBeforeMaturityByBuyer,
                    minLeverage: _daiMinLeverage
                });
        } else {
            revert(IporErrors.WRONG_ADDRESS);
        }
    }

    function _closeSwaps(
        address onBehalfOf,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        PoolConfiguration memory poolCfg
    )
        internal
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        require(
            payFixedSwapIds.length <= poolCfg.liquidationLegLimit &&
                receiveFixedSwapIds.length <= poolCfg.liquidationLegLimit,
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );

        uint256 payoutForLiquidatorPayFixed;
        uint256 payoutForLiquidatorReceiveFixed;

        (payoutForLiquidatorPayFixed, closedPayFixedSwaps) = _closeSwapsPayFixed(onBehalfOf, payFixedSwapIds, poolCfg);

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsReceiveFixed(
            onBehalfOf,
            receiveFixedSwapIds,
            poolCfg
        );

        _transferLiquidationDepositAmount(
            poolCfg.asset,
            poolCfg.decimals,
            onBehalfOf,
            payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed
        );
    }

    function _closeSwapPayFixed(
        address onBehalfOf,
        IporTypes.IporSwapMemory memory iporSwap,
        PoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 closeTimestamp = block.timestamp;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
            closeTimestamp,
            poolCfg.asset
        );

        int256 payoff = _calculatePayoff(
            poolCfg,
            iporSwap,
            0,
            closeTimestamp,
            iporSwap.calculatePayoffPayFixed(closeTimestamp, accruedIpor.ibtPrice),
            accruedIpor.indexValue
        );

        IMiltonStorage(poolCfg.ammStorage).updateStorageWhenCloseSwapPayFixed(iporSwap, payoff, closeTimestamp);

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(iporSwap, payoff, poolCfg);

        emit CloseSwap(iporSwap.id, poolCfg.asset, closeTimestamp, onBehalfOf, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapReceiveFixed(
        address onBehalfOf,
        IporTypes.IporSwapMemory memory iporSwap,
        PoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator) {
        uint256 closeTimestamp = block.timestamp;

        IporTypes.AccruedIpor memory accruedIpor = IIporOracle(_iporOracle).getAccruedIndex(
            closeTimestamp,
            poolCfg.asset
        );

        int256 payoff = _calculatePayoff(
            poolCfg,
            iporSwap,
            1,
            closeTimestamp,
            iporSwap.calculatePayoffReceiveFixed(closeTimestamp, accruedIpor.ibtPrice),
            accruedIpor.indexValue
        );

        IMiltonStorage(poolCfg.ammStorage).updateStorageWhenCloseSwapReceiveFixed(iporSwap, payoff, closeTimestamp);

        uint256 transferredToBuyer;

        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(iporSwap, payoff, poolCfg);

        emit CloseSwap(iporSwap.id, poolCfg.asset, closeTimestamp, onBehalfOf, transferredToBuyer, payoutForLiquidator);
    }

    function _closeSwapsPayFixed(
        address onBehalfOf,
        uint256[] memory swapIds,
        PoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        require(swapIds.length <= poolCfg.liquidationLegLimit, MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED);

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            uint256 swapId = swapIds[i];
            require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

            IporTypes.IporSwapMemory memory iporSwap = IMiltonStorage(poolCfg.ammStorage).getSwapPayFixed(swapId);

            if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                payoutForLiquidator += _closeSwapPayFixed(onBehalfOf, iporSwap, poolCfg);
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
            }
        }
    }

    function _closeSwapsReceiveFixed(
        address onBehalfOf,
        uint256[] memory swapIds,
        PoolConfiguration memory poolCfg
    ) internal returns (uint256 payoutForLiquidator, AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        require(swapIds.length <= poolCfg.liquidationLegLimit, MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED);

        closedSwaps = new AmmTypes.IporSwapClosingResult[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            uint256 swapId = swapIds[i];
            require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

            IporTypes.IporSwapMemory memory iporSwap = IMiltonStorage(poolCfg.ammStorage).getSwapReceiveFixed(swapId);

            if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                payoutForLiquidator += _closeSwapReceiveFixed(onBehalfOf, iporSwap, poolCfg);
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = AmmTypes.IporSwapClosingResult(swapId, false);
            }
        }
    }

    function _closeSwapsPayFixedWithTransferLiquidationDeposit(
        address asset,
        address onBehalfOf,
        uint256[] memory swapIds
    ) internal returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        PoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsPayFixed(onBehalfOf, swapIds, poolCfg);

        _transferLiquidationDepositAmount(asset, poolCfg.decimals, onBehalfOf, payoutForLiquidator);
    }

    function _closeSwapsReceiveFixedWithTransferLiquidationDeposit(
        address asset,
        address onBehalfOf,
        uint256[] memory swapIds
    ) internal returns (AmmTypes.IporSwapClosingResult[] memory closedSwaps) {
        PoolConfiguration memory poolCfg = _getPoolConfiguration(asset);

        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsReceiveFixed(onBehalfOf, swapIds, poolCfg);

        _transferLiquidationDepositAmount(asset, poolCfg.decimals, onBehalfOf, payoutForLiquidator);
    }

    /// @notice Transfer sum of all liquidation deposits to liquidator
    /// @param liquidator address of liquidator
    /// @param liquidationDepositAmount liquidation deposit amount, value represented in 18 decimals
    function _transferLiquidationDepositAmount(
        address asset,
        uint256 decimals,
        address liquidator,
        uint256 liquidationDepositAmount
    ) internal {
        if (liquidationDepositAmount > 0) {
            IERC20Upgradeable(asset).safeTransfer(
                liquidator,
                IporMath.convertWadToAssetDecimals(liquidationDepositAmount, decimals)
            );
        }
    }

    function _calculatePayoff(
        PoolConfiguration memory poolCfg,
        IporTypes.IporSwapMemory memory iporSwap,
        uint256 direction,
        uint256 closeTimestamp,
        int256 swapPayoffToDate,
        uint256 indexValue
    ) internal returns (int256 payoff) {
        int256 swapUnwindValueAndOpeningFee;

        if (
            _validateAllowanceToCloseSwap(
                OwnerManager.getOwner(),
                iporSwap,
                swapPayoffToDate,
                closeTimestamp,
                poolCfg
            ) == true
        ) {
            uint256 oppositeLegFixedRate = RiskManagementLogic.calculateQuote(
                iporSwap.notional,
                direction == 0 ? 1 : 0,
                iporSwap.duration,
                RiskManagementLogic.SpreadQuoteContext({
                    asset: poolCfg.asset,
                    ammStorage: poolCfg.ammStorage,
                    iporRiskManagementOracle: _iporRiskManagementOracle,
                    spreadRouter: _spreadRouter,
                    minLeverage: poolCfg.minLeverage,
                    indexValue: indexValue
                })
            );

            int256 swapUnwindValue = iporSwap.calculateSwapUnwindValue(
                closeTimestamp,
                swapPayoffToDate,
                oppositeLegFixedRate,
                poolCfg.openingFeeRateForSwapUnwind
            );

            uint256 swapUnwindOpeningFee = IporMath.division(
                iporSwap.notional * poolCfg.openingFeeRate * IporMath.division(28 * Constants.D18, 365),
                Constants.D36
            );

            swapUnwindValueAndOpeningFee = swapUnwindValue - swapUnwindOpeningFee.toInt256();

            emit SwapUnwind(iporSwap.id, swapPayoffToDate, swapUnwindValue, swapUnwindOpeningFee);
        }

        payoff = swapPayoffToDate + swapUnwindValueAndOpeningFee;
    }

    /**
     * @notice Function that transfers payout of the swap to the owner.
     * @dev Function:
     * # checks if swap profit, loss or maturity allows for liquidataion
     * # checks if swap's payout is larger than the collateral used to open it
     * # should the payout be larger than the collateral then it transfers payout to the buyer
     * @param derivativeItem - Derivative struct
     * @param payoff - Net earnings of the derivative. Can be positive (swap has a possitive earnings) or negative (swap looses)
     * @param poolCfg - Pool configuration
     **/
    function _transferTokensBasedOnPayoff(
        IporTypes.IporSwapMemory memory derivativeItem,
        int256 payoff,
        PoolConfiguration memory poolCfg
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPayoff = IporMath.absoluteValue(payoff);

        if (payoff > 0) {
            //Buyer earns, Milton looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral + absPayoff,
                poolCfg
            );
        } else {
            //Milton earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral - absPayoff,
                poolCfg
            );
        }
    }

    function _validateAllowanceToCloseSwap(
        address owner,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closeTimestamp,
        PoolConfiguration memory poolCfg
    ) internal view returns (bool swapUnwindRequired) {
        uint256 closableStatus = _getClosableStatusForSwap(owner, iporSwap, payoff, closeTimestamp, poolCfg);

        if (closableStatus == 1) revert(MiltonErrors.INCORRECT_SWAP_STATUS);
        if (closableStatus == 2) revert(MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR);

        if (closableStatus == 3 || closableStatus == 4) {
            if (msg.sender == iporSwap.buyer) {
                swapUnwindRequired = true;
            } else {
                if (closableStatus == 3) revert(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER);
                if (closableStatus == 4) revert(MiltonErrors.CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY);
            }
        }
    }

    function _closeSwapPayFixedWithTransferLiquidationDeposit(
        address onBehalfOf,
        uint256 swapId,
        PoolConfiguration memory poolCfg
    ) internal {
        require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

        _transferLiquidationDepositAmount(
            poolCfg.asset,
            poolCfg.decimals,
            onBehalfOf,
            _closeSwapPayFixed(onBehalfOf, IMiltonStorage(poolCfg.ammStorage).getSwapPayFixed(swapId), poolCfg)
        );
    }

    function _closeSwapReceiveFixedWithTransferLiquidationDeposit(
        address onBehalfOf,
        uint256 swapId,
        PoolConfiguration memory poolCfg
    ) internal {
        require(swapId > 0, MiltonErrors.INCORRECT_SWAP_ID);

        _transferLiquidationDepositAmount(
            poolCfg.asset,
            poolCfg.decimals,
            onBehalfOf,
            _closeSwapReceiveFixed(onBehalfOf, IMiltonStorage(poolCfg.ammStorage).getSwapReceiveFixed(swapId), poolCfg)
        );
    }

    /// @notice Check closable status for Swap given as a parameter.
    /// @param owner The address of the owner
    /// @param iporSwap The swap to be checked
    /// @param payoff The payoff of the swap
    /// @param closeTimestamp The timestamp of closing
    /// @return closableStatus Closable status for Swap.
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Buyer
    /// 4 - Cannot close swap, closing is too early for Community
    function _getClosableStatusForSwap(
        address owner,
        IporTypes.IporSwapMemory memory iporSwap,
        int256 payoff,
        uint256 closeTimestamp,
        PoolConfiguration memory poolCfg
    ) internal view returns (uint256) {
        if (iporSwap.state != uint256(AmmTypes.SwapState.ACTIVE)) {
            return 1;
        }

        address msgSender = msg.sender;

        if (msgSender != owner) {
            uint256 absPayoff = IporMath.absoluteValue(payoff);

            uint256 minPayoffToCloseBeforeMaturityByCommunity = IporMath.percentOf(
                iporSwap.collateral,
                poolCfg.minLiquidationThresholdToCloseBeforeMaturityByCommunity
            );

            uint256 swapEndTimestamp = iporSwap.calculateSwapMaturity();

            if (closeTimestamp >= swapEndTimestamp) {
                if (absPayoff < minPayoffToCloseBeforeMaturityByCommunity || absPayoff == iporSwap.collateral) {
                    if (AmmConfigurationManager.isSwapLiquidator(msgSender) != true && msgSender != iporSwap.buyer) {
                        return 2;
                    }
                }
            } else {
                uint256 minPayoffToCloseBeforeMaturityByBuyer = IporMath.percentOf(
                    iporSwap.collateral,
                    poolCfg.minLiquidationThresholdToCloseBeforeMaturityByBuyer
                );

                if (
                    (absPayoff >= minPayoffToCloseBeforeMaturityByBuyer &&
                        absPayoff < minPayoffToCloseBeforeMaturityByCommunity) || absPayoff == iporSwap.collateral
                ) {
                    if (AmmConfigurationManager.isSwapLiquidator(msgSender) != true && msgSender != iporSwap.buyer) {
                        return 2;
                    }
                }

                if (absPayoff < minPayoffToCloseBeforeMaturityByBuyer) {
                    if (msgSender == iporSwap.buyer) {
                        if (swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByBuyer > closeTimestamp) {
                            return 3;
                        }
                    } else {
                        if (
                            swapEndTimestamp - poolCfg.timeBeforeMaturityAllowedToCloseSwapByCommunity > closeTimestamp
                        ) {
                            return 4;
                        }
                    }
                }
            }
        }

        return 0;
    }

    function _transferDerivativeAmount(
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount,
        PoolConfiguration memory poolCfg
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        if (msg.sender == buyer) {
            transferAmount = transferAmount + liquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from Milton to Liquidator,
            // transfer to be made outside this function, to avoid multiple transfers
            payoutForLiquidator = liquidationDepositAmount;
        }

        if (transferAmount > 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(transferAmount, poolCfg.decimals);
            uint256 wadMiltonErc20BalanceBeforeRedeem = IERC20Upgradeable(poolCfg.asset).balanceOf(poolCfg.ammTreasury);

            if (wadMiltonErc20BalanceBeforeRedeem <= transferAmountAssetDecimals) {
                IporTypes.MiltonBalancesMemory memory balance = AmmLib.getAccruedBalance(
                    poolCfg.ammStorage,
                    poolCfg.assetManagement
                );
                int256 rebalanceAmount = AssetManagementLogic.calculateRebalanceAmountBeforeWithdraw(
                    poolCfg.asset,
                    wadMiltonErc20BalanceBeforeRedeem,
                    balance.vault,
                    transferAmount + liquidationDepositAmount
                );

                if (rebalanceAmount < 0) {
                    IMiltonInternal(poolCfg.ammTreasury).withdrawFromStanley((-rebalanceAmount).toUint256());
                }
            }

            //transfer from Milton to Trader
            IERC20Upgradeable(poolCfg.asset).safeTransfer(buyer, transferAmountAssetDecimals);

            transferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, poolCfg.decimals);
        }
    }

    function _validateAsset(address asset) internal view {
        require(asset == _usdt || asset == _usdc || asset == _dai, IporErrors.WRONG_ADDRESS);
    }

    function _getDecimals(address asset) internal view returns (uint256 decimals) {
        if (asset == _usdt) {
            decimals = _usdtDecimals;
        } else if (asset == _usdc) {
            decimals = _usdcDecimals;
        } else if (asset == _dai) {
            decimals = _daiDecimals;
        } else {
            revert(IporErrors.WRONG_ADDRESS);
        }
    }
}
