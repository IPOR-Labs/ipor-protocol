// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../interfaces/types/AmmTypes.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "./MiltonInternal.sol";
import "./libraries/types/AmmMiltonTypes.sol";
import "./MiltonStorage.sol";

/**
 * @title Milton - Automated Market Maker for trading Interest Rate Swaps derivatives based on IPOR Index.
 * @dev Milton is scoped per asset (USDT, USDC, DAI or other type of ERC20 asset included by the DAO)
 * Users can:
 *  # open and close own interest rate swaps
 *  # liquidate other's swaps at maturity
 *  # calculate the SOAP
 *  # calculate spread
 * @author IPOR Labs
 */
abstract contract Milton is MiltonInternal, IMilton {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for IporTypes.IporSwapMemory;

    /**
     * @param asset - Instance of Milton is initialised in the context of the given ERC20 asset. Every trasaction is by the default scoped to that ERC20.
     * @param iporOracle - Address of Oracle treated as the source of true IPOR rate.
     * @param miltonStorage - Address of contract responsible for managing the state of Milton.
     * @param miltonSpreadModel - Address of smart contract responsible for calculating spreads on the interst rate swaps.
     * @param stanley - Address of smart contract responsible for asset management.
     * For more details refer to the documentation: https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/asset-management
     **/

    function initialize(
        address asset,
        address iporOracle,
        address miltonStorage,
        address miltonSpreadModel,
        address stanley
    ) public initializer {
        __Ownable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonSpreadModel != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == ERC20Upgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        _miltonStorage = IMiltonStorage(miltonStorage);
        _miltonSpreadModel = IMiltonSpreadModel(miltonSpreadModel);
        _iporOracle = IIporOracle(iporOracle);
        _asset = asset;
        _stanley = IStanley(stanley);
    }

    function calculateSpread()
        external
        view
        override
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        (spreadPayFixed, spreadReceiveFixed) = _calculateSpread(block.timestamp);
    }

    function calculateSoap()
        external
        view
        override
        returns (
            int256 soapPayFixed,
            int256 soapReceiveFixed,
            int256 soap
        )
    {
        (int256 _soapPayFixed, int256 _soapReceiveFixed, int256 _soap) = _calculateSoap(
            block.timestamp
        );
        return (soapPayFixed = _soapPayFixed, soapReceiveFixed = _soapReceiveFixed, soap = _soap);
    }

    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return
            _openSwapPayFixed(block.timestamp, totalAmount, acceptableFixedInterestRate, leverage);
    }

    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return
            _openSwapReceiveFixed(
                block.timestamp,
                totalAmount,
                acceptableFixedInterestRate,
                leverage
            );
    }

    function closeSwapPayFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        _closeSwapPayFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function closeSwapReceiveFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function closeSwaps(uint256[] memory payFixedSwapIds, uint256[] memory receiveFixedSwapIds)
        external
        override
        nonReentrant
        whenNotPaused
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        (closedPayFixedSwaps, closedReceiveFixedSwaps) = _closeSwaps(
            payFixedSwapIds,
            receiveFixedSwapIds,
            block.timestamp
        );
    }

    function emergencyCloseSwapPayFixed(uint256 swapId) external override onlyOwner whenPaused {
        _closeSwapPayFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function emergencyCloseSwapReceiveFixed(uint256 swapId) external override onlyOwner whenPaused {
        _closeSwapReceiveFixedWithTransferLiquidationDeposit(swapId, block.timestamp);
    }

    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsPayFixedWithTransferLiquidationDeposit(swapIds, block.timestamp);
    }

    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
        returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps)
    {
        closedSwaps = _closeSwapsReceiveFixedWithTransferLiquidationDeposit(
            swapIds,
            block.timestamp
        );
    }

    function _closeSwaps(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        uint256 closeTimestamp
    )
        internal
        returns (
            MiltonTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            MiltonTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        )
    {
        require(
            payFixedSwapIds.length <= _getLiquidationLegLimit() &&
                receiveFixedSwapIds.length <= _getLiquidationLegLimit(),
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );

        uint256 payoutForLiquidatorPayFixed;
        uint256 payoutForLiquidatorReceiveFixed;

        (payoutForLiquidatorPayFixed, closedPayFixedSwaps) = _closeSwapsPayFixed(
            payFixedSwapIds,
            closeTimestamp
        );

        (payoutForLiquidatorReceiveFixed, closedReceiveFixedSwaps) = _closeSwapsReceiveFixed(
            receiveFixedSwapIds,
            closeTimestamp
        );

        _transferLiquidationDepositAmount(
            _msgSender(),
            payoutForLiquidatorPayFixed + payoutForLiquidatorReceiveFixed
        );
    }

    function _closeSwapPayFixedWithTransferLiquidationDeposit(
        uint256 swapId,
        uint256 closeTimestamp
    ) internal {
        require(swapId != 0, MiltonErrors.INCORRECT_SWAP_ID);

        IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapPayFixed(swapId);

        _transferLiquidationDepositAmount(
            _msgSender(),
            _closeSwapPayFixed(iporSwap, closeTimestamp)
        );
    }

    function _closeSwapReceiveFixedWithTransferLiquidationDeposit(
        uint256 swapId,
        uint256 closeTimestamp
    ) internal {
        require(swapId != 0, MiltonErrors.INCORRECT_SWAP_ID);

        IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapReceiveFixed(swapId);

        _transferLiquidationDepositAmount(
            _msgSender(),
            _closeSwapReceiveFixed(iporSwap, closeTimestamp)
        );
    }

    function _closeSwapsPayFixedWithTransferLiquidationDeposit(
        uint256[] memory swapIds,
        uint256 closeTimestamp
    ) internal returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsPayFixed(swapIds, closeTimestamp);
        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidator);
    }

    function _closeSwapsReceiveFixedWithTransferLiquidationDeposit(
        uint256[] memory swapIds,
        uint256 closeTimestamp
    ) internal returns (MiltonTypes.IporSwapClosingResult[] memory closedSwaps) {
        uint256 payoutForLiquidator;
        (payoutForLiquidator, closedSwaps) = _closeSwapsReceiveFixed(swapIds, closeTimestamp);
        _transferLiquidationDepositAmount(_msgSender(), payoutForLiquidator);
    }

    function _calculateIncomeFeeValue(int256 payoff) internal pure returns (uint256) {
        return
            IporMath.division(IporMath.absoluteValue(payoff) * _getIncomeFeeRate(), Constants.D18);
    }

    function _calculateSpread(uint256 calculateTimestamp)
        internal
        view
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        IporTypes.AccruedIpor memory accruedIpor = _iporOracle.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();

        spreadPayFixed = _getMiltonSpreadModel().calculateSpreadPayFixed(accruedIpor, balance);

        spreadReceiveFixed = _getMiltonSpreadModel().calculateSpreadReceiveFixed(
            accruedIpor,
            balance
        );
    }

    function _beforeOpenSwap(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 leverage
    ) internal view returns (AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(totalAmount != 0, MiltonErrors.TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20Upgradeable(_asset).balanceOf(_msgSender()) >= totalAmount,
            IporErrors.ASSET_BALANCE_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, _getDecimals());

        require(leverage >= _getMinLeverage(), MiltonErrors.LEVERAGE_TOO_LOW);
        require(leverage <= _getMaxLeverage(), MiltonErrors.LEVERAGE_TOO_HIGH);

        uint256 liquidationDepositAmount = _getLiquidationDepositAmount();
        uint256 wadLiquidationDepositAmount = liquidationDepositAmount * Constants.D18;

        require(
            wadTotalAmount > wadLiquidationDepositAmount + _getIporPublicationFee(),
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = IporSwapLogic
            .calculateSwapAmount(
                wadTotalAmount,
                leverage,
                wadLiquidationDepositAmount,
                _getIporPublicationFee(),
                _getOpeningFeeRate()
            );

        (uint256 openingFeeLPAmount, uint256 openingFeeTreasuryAmount) = _splitOpeningFeeAmount(
            openingFeeAmount,
            _getOpeningFeeTreasuryPortionRate()
        );

        require(
            collateral <= _getMaxSwapCollateralAmount(),
            MiltonErrors.COLLATERAL_AMOUNT_TOO_HIGH
        );

        require(
            wadTotalAmount >
                wadLiquidationDepositAmount + _getIporPublicationFee() + openingFeeAmount,
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        return
            AmmMiltonTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFeeLPAmount,
                openingFeeTreasuryAmount,
                _getIporPublicationFee(),
                liquidationDepositAmount,
                _iporOracle.getAccruedIndex(openTimestamp, _asset)
            );
    }

    function _splitOpeningFeeAmount(uint256 openingFeeAmount, uint256 openingFeeForTreasureRate)
        internal
        pure
        returns (uint256 liquidityPoolAmount, uint256 treasuryAmount)
    {
        treasuryAmount = IporMath.division(
            openingFeeAmount * openingFeeForTreasureRate,
            Constants.D18
        );
        liquidityPoolAmount = openingFeeAmount - treasuryAmount;
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function _openSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            leverage
        );

        IporTypes.MiltonBalancesMemory memory balance = _getMiltonStorage().getBalance();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralPayFixed = balance.totalCollateralPayFixed + bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.totalCollateralPayFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed
        );

        uint256 quoteValue = _getMiltonSpreadModel().calculateQuotePayFixed(
            bosStruct.accruedIpor,
            balance
        );

        require(
            acceptableFixedInterestRate != 0 && quoteValue <= acceptableFixedInterestRate,
            MiltonErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED
        );

        MiltonTypes.IporSwapIndicator memory indicator = _calculateSwapIndicators(
            openTimestamp,
            bosStruct.notional,
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _msgSender(),
            openTimestamp,
            bosStruct.collateral,
            bosStruct.notional,
            indicator.ibtQuantity,
            indicator.fixedInterestRate,
            bosStruct.liquidationDepositAmount,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount
        );

        uint256 newSwapId = _getMiltonStorage().updateStorageWhenOpenSwapPayFixed(
            newSwap,
            _getIporPublicationFee()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), totalAmount);

        _emitOpenSwapEvent(
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            0,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function _openSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            leverage
        );

        IporTypes.MiltonBalancesMemory memory balance = _getMiltonStorage().getBalance();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralReceiveFixed =
            balance.totalCollateralReceiveFixed +
            bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.totalCollateralReceiveFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed
        );

        uint256 quoteValue = _getMiltonSpreadModel().calculateQuoteReceiveFixed(
            bosStruct.accruedIpor,
            balance
        );
        require(
            acceptableFixedInterestRate <= quoteValue,
            MiltonErrors.ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED
        );

        MiltonTypes.IporSwapIndicator memory indicator = _calculateSwapIndicators(
            openTimestamp,
            bosStruct.notional,
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            _msgSender(),
            openTimestamp,
            bosStruct.collateral,
            bosStruct.notional,
            indicator.ibtQuantity,
            indicator.fixedInterestRate,
            bosStruct.liquidationDepositAmount,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount
        );

        uint256 newSwapId = _getMiltonStorage().updateStorageWhenOpenSwapReceiveFixed(
            newSwap,
            _getIporPublicationFee()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), totalAmount);

        _emitOpenSwapEvent(
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            1,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    function _validateLiqudityPoolUtylization(
        uint256 totalLiquidityPoolBalance,
        uint256 collateralPerLegBalance,
        uint256 totalCollateralBalance
    ) internal pure {
        uint256 utilizationRate;
        uint256 utilizationRatePerLeg;

        if (totalLiquidityPoolBalance != 0) {
            utilizationRate = IporMath.division(
                totalCollateralBalance * Constants.D18,
                totalLiquidityPoolBalance
            );

            utilizationRatePerLeg = IporMath.division(
                collateralPerLegBalance * Constants.D18,
                totalLiquidityPoolBalance
            );
        } else {
            utilizationRate = Constants.MAX_VALUE;
            utilizationRatePerLeg = Constants.MAX_VALUE;
        }

        require(
            utilizationRate <= _getMaxLpUtilizationRate(),
            MiltonErrors.LP_UTILIZATION_EXCEEDED
        );

        require(
            utilizationRatePerLeg <= _getMaxLpUtilizationPerLegRate(),
            MiltonErrors.LP_UTILIZATION_PER_LEG_EXCEEDED
        );
    }

    function _emitOpenSwapEvent(
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        MiltonTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationFee
    ) internal {
        emit OpenSwap(
            newSwapId,
            newSwap.buyer,
            _asset,
            MiltonTypes.SwapDirection(direction),
            AmmTypes.OpenSwapMoney(
                wadTotalAmount,
                newSwap.collateral,
                newSwap.notional,
                newSwap.openingFeeLPAmount,
                newSwap.openingFeeTreasuryAmount,
                iporPublicationFee,
                newSwap.liquidationDepositAmount * Constants.D18
            ),
            newSwap.openTimestamp,
            newSwap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator
        );
    }

    function _calculateSwapIndicators(
        uint256 calculateTimestamp,
        uint256 notional,
        uint256 quoteValue
    ) internal view returns (MiltonTypes.IporSwapIndicator memory indicator) {
        IporTypes.AccruedIpor memory accruedIpor = _iporOracle.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        indicator = MiltonTypes.IporSwapIndicator(
            accruedIpor.indexValue,
            accruedIpor.ibtPrice,
            IporMath.division(notional * Constants.D18, accruedIpor.ibtPrice),
            quoteValue
        );
    }

    function _closeSwapPayFixed(IporTypes.IporSwapMemory memory iporSwap, uint256 closeTimestamp)
        internal
        returns (uint256 payoutForLiquidator)
    {
        require(
            iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE),
            MiltonErrors.INCORRECT_SWAP_STATUS
        );

        int256 payoff = _calculatePayoffPayFixed(closeTimestamp, iporSwap);
        uint256 incomeFeeValue = _calculateIncomeFeeValue(payoff);
        _getMiltonStorage().updateStorageWhenCloseSwapPayFixed(
            _msgSender(),
            iporSwap,
            payoff,
            incomeFeeValue,
            closeTimestamp,
            _getMinLiquidationThresholdToCloseBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        uint256 transferredToBuyer;
        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(
            iporSwap,
            payoff,
            incomeFeeValue,
            closeTimestamp,
            _getMinLiquidationThresholdToCloseBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        emit CloseSwap(
            iporSwap.id,
            _asset,
            closeTimestamp,
            _msgSender(),
            transferredToBuyer,
            payoutForLiquidator,
            incomeFeeValue
        );
    }

    function _closeSwapReceiveFixed(
        IporTypes.IporSwapMemory memory iporSwap,
        uint256 closeTimestamp
    ) internal returns (uint256 payoutForLiquidator) {
        require(
            iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE),
            MiltonErrors.INCORRECT_SWAP_STATUS
        );

        int256 payoff = _calculatePayoffReceiveFixed(closeTimestamp, iporSwap);
        uint256 incomeFeeValue = _calculateIncomeFeeValue(payoff);

        _getMiltonStorage().updateStorageWhenCloseSwapReceiveFixed(
            _msgSender(),
            iporSwap,
            payoff,
            incomeFeeValue,
            closeTimestamp,
            _getMinLiquidationThresholdToCloseBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        uint256 transferredToBuyer;
        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPayoff(
            iporSwap,
            payoff,
            incomeFeeValue,
            closeTimestamp,
            _getMinLiquidationThresholdToCloseBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );
        emit CloseSwap(
            iporSwap.id,
            _asset,
            closeTimestamp,
            _msgSender(),
            incomeFeeValue,
            payoutForLiquidator,
            incomeFeeValue
        );
    }

    function _closeSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        internal
        returns (
            uint256 payoutForLiquidator,
            MiltonTypes.IporSwapClosingResult[] memory closedSwaps
        )
    {
        require(
            swapIds.length <= _getLiquidationLegLimit(),
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );

        closedSwaps = new MiltonTypes.IporSwapClosingResult[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            uint256 swapId = swapIds[i];
            require(swapId != 0, MiltonErrors.INCORRECT_SWAP_ID);

            IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapPayFixed(swapId);

            if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                payoutForLiquidator += _closeSwapPayFixed(iporSwap, closeTimestamp);
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
            }
        }
    }

    function _closeSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp)
        internal
        returns (
            uint256 payoutForLiquidator,
            MiltonTypes.IporSwapClosingResult[] memory closedSwaps
        )
    {
        require(
            swapIds.length <= _getLiquidationLegLimit(),
            MiltonErrors.LIQUIDATION_LEG_LIMIT_EXCEEDED
        );

        closedSwaps = new MiltonTypes.IporSwapClosingResult[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            uint256 swapId = swapIds[i];
            require(swapId != 0, MiltonErrors.INCORRECT_SWAP_ID);

            IporTypes.IporSwapMemory memory iporSwap = _getMiltonStorage().getSwapReceiveFixed(
                swapId
            );

            if (iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE)) {
                payoutForLiquidator += _closeSwapReceiveFixed(iporSwap, closeTimestamp);
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, true);
            } else {
                closedSwaps[i] = MiltonTypes.IporSwapClosingResult(swapId, false);
            }
        }
    }

    /**
     * @notice Function that transfers payout of the swap to the owner.
     * @dev Function:
     * # checks if swap profit, loss or maturity allows for liquidataion
     * # checks if swap's payout is larger than the collateral used to open it
     * # should the payout be larger than the collateral then it transfers payout to the buyer
     * @param derivativeItem - Derivative struct
     * @param payoff - Net earnings of the derivative. Can be positive (swap has a possitive earnings) or negative (swap looses)
     * @param _calculationTimestamp - Time for which the calculations in this funciton are run
     * @param cfgMinLiquidationThresholdToCloseBeforeMaturity - Minimal profit to loss required to put the swap up for the liquidation by non-byer regardless of maturity
     * @param cfgSecondsBeforeMaturityWhenPositionCanBeClosed - Time before the appointed maturity allowing the liquidation of the swap
     * for more information on liquidations refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidations
     **/

    function _transferTokensBasedOnPayoff(
        IporTypes.IporSwapMemory memory derivativeItem,
        int256 payoff,
        uint256 incomeFeeValue,
        uint256 _calculationTimestamp,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPayoff = IporMath.absoluteValue(payoff);
        uint256 minPayoffToCloseBeforeMaturity = IporMath.percentOf(
            derivativeItem.collateral,
            cfgMinLiquidationThresholdToCloseBeforeMaturity
        );

        if (absPayoff < minPayoffToCloseBeforeMaturity) {
            //verify if sender is an owner of swap. If not then check if maturity has been reached - if not then reject, if yes then close even if not an owner
            if (_msgSender() != derivativeItem.buyer) {
                require(
                    _calculationTimestamp >=
                        derivativeItem.endTimestamp -
                            cfgSecondsBeforeMaturityWhenPositionCanBeClosed,
                    MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY
                );
            }
        }

        if (payoff > 0) {
            //Buyer earns, Milton looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral + absPayoff - incomeFeeValue
            );
        } else {
            //Milton earns, Buyer looses
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral - absPayoff
            );
        }
    }

    /**
     * @notice Function that transfers the assets at the time of derivative closing
     * @dev It trasfers the asset to the swap buyer and the liquidator.
     * Should buyer and the liquidator are the same entity it performs only one transfer.
     * @param buyer - address that opened the swap
     * @param liquidationDepositAmount - amount of asset transfered to the liquidator, value represented in 18 decimals
     * @param transferAmount - amount of asset transfered to the swap owner
     **/
    function _transferDerivativeAmount(
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 decimals = _getDecimals();

        if (_msgSender() == buyer) {
            transferAmount = transferAmount + liquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from Milton to Liquidator,
            // transfer to be made outside this function, to avoid multiple transfers
            payoutForLiquidator = liquidationDepositAmount;
        }

        if (transferAmount != 0) {
            uint256 transferAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
                transferAmount,
                decimals
            );
            //transfer from Milton to Trader
            IERC20Upgradeable(_asset).safeTransfer(buyer, transferAmountAssetDecimals);

            transferredToBuyer = IporMath.convertToWad(transferAmountAssetDecimals, decimals);
        }
    }

    //Transfer sum of all liquidation deposits to liquidator
    /// @param liquidator address of liquidator
    /// @param liquidationDepositAmount liquidation deposit amount, value represented in 18 decimals
    function _transferLiquidationDepositAmount(address liquidator, uint256 liquidationDepositAmount)
        internal
    {
        if (liquidationDepositAmount != 0) {
            IERC20Upgradeable(_asset).safeTransfer(
                liquidator,
                IporMath.convertWadToAssetDecimals(liquidationDepositAmount, _getDecimals())
            );
        }
    }

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
