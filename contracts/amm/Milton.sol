// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

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

import "hardhat/console.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
abstract contract Milton is MiltonInternal, IMilton {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for IporTypes.IporSwapMemory;

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
        returns (uint256 spreadPayFixed, uint256 spreadReceiveFixed)
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

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 maxAcceptableFixedInterestRate,
        uint256 leverage
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return
            _openSwapPayFixed(
                block.timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            );
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 maxAcceptableFixedInterestRate,
        uint256 leverage
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return
            _openSwapReceiveFixed(
                block.timestamp,
                totalAmount,
                maxAcceptableFixedInterestRate,
                leverage
            );
    }

    function closeSwapPayFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        uint256 payoutForLiquidator = _closeSwapPayFixed(swapId, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function closeSwapReceiveFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        uint256 payoutForLiquidator = _closeSwapReceiveFixed(swapId, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function closeSwapsPayFixed(uint256[] memory swapIds)
        external
        override
        nonReentrant
        whenNotPaused
    {
        uint256 payoutForLiquidator = _closeSwapsPayFixed(swapIds, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function closeSwapsReceiveFixed(uint256[] memory swapIds)
        external
        override
        nonReentrant
        whenNotPaused
    {
        uint256 payoutForLiquidator = _closeSwapsReceiveFixed(swapIds, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function emergencyCloseSwapPayFixed(uint256 swapId) external override onlyOwner whenPaused {
        uint256 payoutForLiquidator = _closeSwapPayFixed(swapId, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function emergencyCloseSwapReceiveFixed(uint256 swapId) external override onlyOwner whenPaused {
        uint256 payoutForLiquidator = _closeSwapReceiveFixed(swapId, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
    {
        uint256 payoutForLiquidator = _closeSwapsPayFixed(swapIds, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
    {
        uint256 payoutForLiquidator = _closeSwapsReceiveFixed(swapIds, block.timestamp);
        _transferLiquidationDepositAmount(msg.sender, payoutForLiquidator);
    }

    function _calculateIncomeFeeValue(int256 positionValue) internal pure returns (uint256) {
        return
            IporMath.division(
                IporMath.absoluteValue(positionValue) * _getIncomeFeeRate(),
                Constants.D18
            );
    }

    function _calculateSpread(uint256 calculateTimestamp)
        internal
        view
        returns (uint256 spreadPayFixed, uint256 spreadReceiveFixed)
    {
        IporTypes.AccruedIpor memory accruedIpor = _iporOracle.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();

        spreadPayFixed = _miltonSpreadModel.calculateSpreadPayFixed(
            _miltonStorage.calculateSoapPayFixed(accruedIpor.ibtPrice, calculateTimestamp),
            accruedIpor,
            balance
        );
        spreadReceiveFixed = _miltonSpreadModel.calculateSpreadReceiveFixed(
            _miltonStorage.calculateSoapReceiveFixed(accruedIpor.ibtPrice, calculateTimestamp),
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
            IERC20Upgradeable(_asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.ASSET_BALANCE_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, _getDecimals());

        require(leverage >= _getMinLeverage(), MiltonErrors.LEVERAGE_TOO_LOW);
        require(leverage <= _getMaxLeverage(), MiltonErrors.LEVERAGE_TOO_HIGH);

        require(
            wadTotalAmount > _getLiquidationDepositAmount() + _getIporPublicationFee(),
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = IporSwapLogic
            .calculateSwapAmount(
                wadTotalAmount,
                leverage,
                _getLiquidationDepositAmount(),
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
                _getLiquidationDepositAmount() + _getIporPublicationFee() + openingFeeAmount,
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
                _getLiquidationDepositAmount(),
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
        uint256 maxAcceptableFixedInterestRate,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            leverage
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralPayFixed = balance.totalCollateralPayFixed + bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.totalCollateralPayFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuotePayFixed(
            _miltonStorage.calculateSoapPayFixed(bosStruct.accruedIpor.ibtPrice, openTimestamp),
            bosStruct.accruedIpor,
            balance
        );

        require(
            maxAcceptableFixedInterestRate != 0 && quoteValue <= maxAcceptableFixedInterestRate,
            MiltonErrors.TOLERATED_QUOTE_VALUE_EXCEEDED
        );

        MiltonTypes.IporSwapIndicator memory indicator = _calculateSwapdicators(
            openTimestamp,
            bosStruct.notional,
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            msg.sender,
            openTimestamp,
            bosStruct.collateral,
            bosStruct.liquidationDepositAmount,
            bosStruct.notional,
            indicator.fixedInterestRate,
            indicator.ibtQuantity,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount
        );

        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapPayFixed(
            newSwap,
            _getIporPublicationFee()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), totalAmount);

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
        uint256 maxAcceptableFixedInterestRate,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            leverage
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPAmount;
        balance.totalCollateralReceiveFixed =
            balance.totalCollateralReceiveFixed +
            bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.totalCollateralReceiveFixed,
            balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuoteReceiveFixed(
            _miltonStorage.calculateSoapReceiveFixed(bosStruct.accruedIpor.ibtPrice, openTimestamp),
            bosStruct.accruedIpor,
            balance
        );

        require(
            maxAcceptableFixedInterestRate != 0 && quoteValue <= maxAcceptableFixedInterestRate,
            MiltonErrors.TOLERATED_QUOTE_VALUE_EXCEEDED
        );

        MiltonTypes.IporSwapIndicator memory indicator = _calculateSwapdicators(
            openTimestamp,
            bosStruct.notional,
            quoteValue
        );

        AmmTypes.NewSwap memory newSwap = AmmTypes.NewSwap(
            msg.sender,
            openTimestamp,
            bosStruct.collateral,
            bosStruct.liquidationDepositAmount,
            bosStruct.notional,
            indicator.fixedInterestRate,
            indicator.ibtQuantity,
            bosStruct.openingFeeLPAmount,
            bosStruct.openingFeeTreasuryAmount
        );

        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapReceiveFixed(
            newSwap,
            _getIporPublicationFee()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), totalAmount);

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
                newSwap.liquidationDepositAmount
            ),
            newSwap.openTimestamp,
            newSwap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator
        );
    }

    function _calculateSwapdicators(
        uint256 calculateTimestamp,
        uint256 notional,
        uint256 quoteValue
    ) internal view returns (MiltonTypes.IporSwapIndicator memory indicator) {
        IporTypes.AccruedIpor memory accruedIpor = _iporOracle.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        require(accruedIpor.ibtPrice != 0, MiltonErrors.IBT_PRICE_CANNOT_BE_ZERO);

        indicator = MiltonTypes.IporSwapIndicator(
            accruedIpor.indexValue,
            accruedIpor.ibtPrice,
            IporMath.division(notional * Constants.D18, accruedIpor.ibtPrice),
            quoteValue
        );
    }

    function _closeSwapPayFixed(uint256 swapId, uint256 closeTimestamp) internal returns (uint256 payoutForLiquidator) {
        require(swapId != 0, MiltonErrors.INCORRECT_SWAP_ID);

        IporTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapPayFixed(swapId);

        require(
            iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE),
            MiltonErrors.INCORRECT_SWAP_STATUS
        );

        int256 positionValue = _calculateSwapPayFixedValue(closeTimestamp, iporSwap);

        _miltonStorage.updateStorageWhenCloseSwapPayFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeFeeRate(),
            _getMinLiquidationThresholdToCloseBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        uint256 transferredToBuyer;
        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPositionValue(
                iporSwap,
                positionValue,
                closeTimestamp,
                _getIncomeFeeRate(),
                _getMinLiquidationThresholdToCloseBeforeMaturity(),
                _getSecondsBeforeMaturityWhenPositionCanBeClosed()
            );

        emit CloseSwap(
            swapId,
            _asset,
            closeTimestamp,
            msg.sender,
            transferredToBuyer,
            payoutForLiquidator
        );
    }

    function _closeSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) internal returns (uint256 payoutForLiquidator)  {
        require(swapId != 0, MiltonErrors.INCORRECT_SWAP_ID);

        IporTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapReceiveFixed(swapId);

        require(
            iporSwap.state == uint256(AmmTypes.SwapState.ACTIVE),
            MiltonErrors.INCORRECT_SWAP_STATUS
        );

        int256 positionValue = _calculateSwapReceiveFixedValue(closeTimestamp, iporSwap);

        _miltonStorage.updateStorageWhenCloseSwapReceiveFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeFeeRate(),
            _getMinLiquidationThresholdToCloseBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        uint256 transferredToBuyer;
        (transferredToBuyer, payoutForLiquidator) = _transferTokensBasedOnPositionValue(
                iporSwap,
                positionValue,
                closeTimestamp,
                _getIncomeFeeRate(),
                _getMinLiquidationThresholdToCloseBeforeMaturity(),
                _getSecondsBeforeMaturityWhenPositionCanBeClosed()
            );

        emit CloseSwap(
            swapId,
            _asset,
            closeTimestamp,
            msg.sender,
            transferredToBuyer,
            payoutForLiquidator
        );
    }

    function _closeSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp) internal returns (uint256 payoutForLiquidator) {
        require(swapIds.length > 0, MiltonErrors.SWAP_IDS_ARRAY_IS_EMPTY);

        for (uint256 i = 0; i < swapIds.length; i++) {
            payoutForLiquidator += _closeSwapPayFixed(swapIds[i], closeTimestamp);
        }
    }

    function _closeSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp) internal returns (uint256 payoutForLiquidator) {
        require(swapIds.length > 0, MiltonErrors.SWAP_IDS_ARRAY_IS_EMPTY);

        for (uint256 i = 0; i < swapIds.length; i++) {
            payoutForLiquidator += _closeSwapReceiveFixed(swapIds[i], closeTimestamp);
        }
    }

    function _transferTokensBasedOnPositionValue(
        IporTypes.IporSwapMemory memory derivativeItem,
        int256 positionValue,
        uint256 _calculationTimestamp,
        uint256 cfgIncomeFeeRate,
        uint256 cfgMinLiquidationThresholdToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 absPositionValue = IporMath.absoluteValue(positionValue);
        uint256 minPositionValueToCloseBeforeMaturity = IporMath.percentOf(
            derivativeItem.collateral,
            cfgMinLiquidationThresholdToCloseBeforeMaturity
        );

        if (absPositionValue < minPositionValueToCloseBeforeMaturity) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (msg.sender != derivativeItem.buyer) {
                require(
                    _calculationTimestamp >=
                        derivativeItem.endTimestamp -
                            cfgSecondsBeforeMaturityWhenPositionCanBeClosed,
                    MiltonErrors.CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY
                );
            }
        }

        if (positionValue > 0) {
            //Trader earn, Milton loose
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral +
                    absPositionValue -
                    IporMath.division(absPositionValue * cfgIncomeFeeRate, Constants.D18)
            );
        } else {
            //Milton earn, Trader looseMiltonStorage
            (transferredToBuyer, payoutForLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral - absPositionValue
            );
        }
    }

    //Transfer only to buyer and returns how much transfer to liquidator (0 if buyer is liquidator)
    function _transferDerivativeAmount(
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount
    ) internal returns (uint256 transferredToBuyer, uint256 payoutForLiquidator) {
        uint256 decimals = _getDecimals();

        if (msg.sender == buyer) {
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
    function _transferLiquidationDepositAmount(
        address liquidator,
        uint256 liquidationDepositAmount
    ) internal {
        if (liquidationDepositAmount != 0) {
            uint256 decimals = _getDecimals();
            uint256 liqDepositAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
                liquidationDepositAmount,
                decimals
            );
            IERC20Upgradeable(_asset).safeTransfer(msg.sender, liqDepositAmountAssetDecimals);
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
