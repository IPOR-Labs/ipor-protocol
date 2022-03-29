// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../interfaces/types/IporTypes.sol";
import "../interfaces/types/AmmTypes.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IWarren.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IJoseph.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "./configuration/MiltonConfiguration.sol";
import "./libraries/types/AmmMiltonTypes.sol";
import "./libraries/IporSwapLogic.sol";
import "./MiltonStorage.sol";

import "hardhat/console.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
abstract contract Milton is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    MiltonConfiguration,
    IMilton
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for IporTypes.IporSwapMemory;

    modifier onlyJoseph() {
        require(msg.sender == _joseph, MiltonErrors.CALLER_NOT_JOSEPH);
        _;
    }

    function initialize(
        address asset,
        address warren,
        address miltonStorage,
        address miltonSpreadModel,
        address stanley
    ) public initializer {
        __Ownable_init();

        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(warren != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonStorage != address(0), IporErrors.WRONG_ADDRESS);
        require(miltonSpreadModel != address(0), IporErrors.WRONG_ADDRESS);
        require(stanley != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == ERC20Upgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        _miltonStorage = IMiltonStorage(miltonStorage);
        _miltonSpreadModel = IMiltonSpreadModel(miltonSpreadModel);
        _warren = IWarren(warren);
        _asset = asset;
        _stanley = IStanley(stanley);
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getAccruedBalance()
        external
        view
        override
        returns (IporTypes.MiltonBalancesMemory memory)
    {
        return _getAccruedBalance();
    }

    function calculateSpread()
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        (spreadPayFixedValue, spreadRecFixedValue) = _calculateSpread(block.timestamp);
    }

    function calculateSoap()
        external
        view
        override
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(block.timestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function calculateSoapForTimestamp(uint256 calculateTimestamp)
        external
        view
        override
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(calculateTimestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function calculateSwapPayFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapPayFixedValue(block.timestamp, swap);
    }

    function calculateSwapReceiveFixedValue(IporTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapReceiveFixedValue(block.timestamp, swap);
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return _openSwapPayFixed(block.timestamp, totalAmount, toleratedQuoteValue, leverage);
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return _openSwapReceiveFixed(block.timestamp, totalAmount, toleratedQuoteValue, leverage);
    }

    function closeSwapPayFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        _closeSwapPayFixed(swapId, block.timestamp);
    }

    function closeSwapReceiveFixed(uint256 swapId) external override nonReentrant whenNotPaused {
        _closeSwapReceiveFixed(swapId, block.timestamp);
    }

    function closeSwapsPayFixed(uint256[] memory swapIds)
        external
        override
        nonReentrant
        whenNotPaused
    {
        _closeSwapsPayFixed(swapIds, block.timestamp);
    }

    function closeSwapsReceiveFixed(uint256[] memory swapIds)
        external
        override
        nonReentrant
        whenNotPaused
    {
        _closeSwapsReceiveFixed(swapIds, block.timestamp);
    }

    function emergencyCloseSwapPayFixed(uint256 swapId) external override onlyOwner whenPaused {
        _closeSwapPayFixed(swapId, block.timestamp);
    }

    function emergencyCloseSwapReceiveFixed(uint256 swapId) external override onlyOwner whenPaused {
        _closeSwapReceiveFixed(swapId, block.timestamp);
    }

    function emergencyCloseSwapsPayFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
    {
        _closeSwapsPayFixed(swapIds, block.timestamp);
    }

    function emergencyCloseSwapsReceiveFixed(uint256[] memory swapIds)
        external
        override
        onlyOwner
        whenPaused
    {
        _closeSwapsReceiveFixed(swapIds, block.timestamp);
    }

    //@param assetValue underlying token amount represented in 18 decimals
    function depositToStanley(uint256 assetValue) external onlyJoseph nonReentrant whenNotPaused {
        uint256 vaultBalance = _stanley.deposit(assetValue);
        _miltonStorage.updateStorageWhenDepositToStanley(assetValue, vaultBalance);
    }

    //@param assetValue underlying token amount represented in 18 decimals
    function withdrawFromStanley(uint256 assetValue)
        external
        nonReentrant
        onlyJoseph
        whenNotPaused
    {
        (uint256 withdrawnValue, uint256 vaultBalance) = _stanley.withdraw(assetValue);
        _miltonStorage.updateStorageWhenWithdrawFromStanley(withdrawnValue, vaultBalance);
    }

    function withdrawAllFromStanley() external nonReentrant onlyJoseph whenNotPaused {
        (uint256 withdrawnValue, uint256 vaultBalance) = _stanley.withdrawAll();
        _miltonStorage.updateStorageWhenWithdrawFromStanley(withdrawnValue, vaultBalance);
    }

    function setupMaxAllowance(address spender) external override onlyOwner whenNotPaused {
        IERC20Upgradeable(_asset).safeIncreaseAllowance(spender, Constants.MAX_VALUE);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getAccruedBalance() internal view returns (IporTypes.MiltonBalancesMemory memory) {
        IporTypes.MiltonBalancesMemory memory accruedBalance = _miltonStorage.getBalance();

        uint256 actualVaultBalance = _stanley.totalBalance(address(this));
        int256 liquidityPool = accruedBalance.liquidityPool.toInt256() +
            actualVaultBalance.toInt256() -
            accruedBalance.vault.toInt256();

        require(liquidityPool >= 0, MiltonErrors.LIQUIDITY_POOL_AMOUNT_TOO_LOW);
        accruedBalance.liquidityPool = liquidityPool.toUint256();

        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }

    function _calculateSwapPayFixedValue(uint256 timestamp, IporTypes.IporSwapMemory memory swap)
        internal
        view
        returns (int256)
    {
        return
            swap.calculateSwapPayFixedValue(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );
    }

    function _calculateSwapReceiveFixedValue(
        uint256 timestamp,
        IporTypes.IporSwapMemory memory swap
    ) internal view returns (int256) {
        return
            swap.calculateSwapReceiveFixedValue(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );
    }

    function _calculateIncomeFeeValue(int256 positionValue) internal pure returns (uint256) {
        return
            IporMath.division(
                IporMath.absoluteValue(positionValue) * _getIncomeFeePercentage(),
                Constants.D18
            );
    }

    function _calculateSpread(uint256 calculateTimestamp)
        internal
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        IporTypes.AccruedIpor memory accruedIpor = _warren.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();

        spreadPayFixedValue = _miltonSpreadModel.calculateSpreadPayFixed(
            _miltonStorage.calculateSoapPayFixed(accruedIpor.ibtPrice, calculateTimestamp),
            accruedIpor,
            balance
        );
        spreadRecFixedValue = _miltonSpreadModel.calculateSpreadRecFixed(
            _miltonStorage.calculateSoapReceiveFixed(accruedIpor.ibtPrice, calculateTimestamp),
            accruedIpor,
            balance
        );
    }

    function _calculateSoap(uint256 calculateTimestamp)
        internal
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        uint256 accruedIbtPrice = _warren.calculateAccruedIbtPrice(_asset, calculateTimestamp);
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _miltonStorage.calculateSoap(
            accruedIbtPrice,
            calculateTimestamp
        );
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
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

        require(leverage >= _getMinLeverageValue(), MiltonErrors.LEVERAGE_TOO_LOW);
        require(leverage <= _getMaxLeverageValue(), MiltonErrors.LEVERAGE_TOO_HIGH);

        require(
            wadTotalAmount > _getLiquidationDepositAmount() + _getIporPublicationFeeAmount(),
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        (uint256 collateral, uint256 notional, uint256 openingFeeAmount) = IporSwapLogic
            .calculateSwapAmount(
                wadTotalAmount,
                leverage,
                _getLiquidationDepositAmount(),
                _getIporPublicationFeeAmount(),
                _getOpeningFeePercentage()
            );

        (uint256 openingFeeLPValue, uint256 openingFeeTreasuryValue) = _splitOpeningFeeAmount(
            openingFeeAmount,
            _getOpeningFeeForTreasuryPercentage()
        );

        require(
            collateral <= _getMaxSwapCollateralAmount(),
            MiltonErrors.COLLATERAL_AMOUNT_TOO_HIGH
        );

        require(
            wadTotalAmount >
                _getLiquidationDepositAmount() + _getIporPublicationFeeAmount() + openingFeeAmount,
            MiltonErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        return
            AmmMiltonTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFeeLPValue,
                openingFeeTreasuryValue,
                _getIporPublicationFeeAmount(),
                _getLiquidationDepositAmount(),
                _warren.getAccruedIndex(openTimestamp, _asset)
            );
    }

    function _splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePercentage
    ) internal pure returns (uint256 liquidityPoolValue, uint256 treasuryValue) {
        treasuryValue = IporMath.division(
            openingFeeAmount * openingFeeForTreasurePercentage,
            Constants.D18
        );
        liquidityPoolValue = openingFeeAmount - treasuryValue;
    }

    //@param totalAmount underlying tokens transferred from buyer to Milton, represented in decimals specific for asset
    function _openSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            leverage
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPValue;
        balance.payFixedTotalCollateral = balance.payFixedTotalCollateral + bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.payFixedTotalCollateral,
            balance.payFixedTotalCollateral + balance.receiveFixedTotalCollateral
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuotePayFixed(
            _miltonStorage.calculateSoapPayFixed(bosStruct.accruedIpor.ibtPrice, openTimestamp),
            bosStruct.accruedIpor,
            balance
        );

        require(
            toleratedQuoteValue != 0 && quoteValue <= toleratedQuoteValue,
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
            bosStruct.openingFeeLPValue,
            bosStruct.openingFeeTreasuryValue
        );

        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapPayFixed(
            newSwap,
            _getIporPublicationFeeAmount()
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
        uint256 toleratedQuoteValue,
        uint256 leverage
    ) internal returns (uint256) {
        AmmMiltonTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            leverage
        );

        IporTypes.MiltonBalancesMemory memory balance = _getAccruedBalance();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFeeLPValue;
        balance.receiveFixedTotalCollateral =
            balance.receiveFixedTotalCollateral +
            bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.receiveFixedTotalCollateral,
            balance.payFixedTotalCollateral + balance.receiveFixedTotalCollateral
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuoteReceiveFixed(
            _miltonStorage.calculateSoapReceiveFixed(bosStruct.accruedIpor.ibtPrice, openTimestamp),
            bosStruct.accruedIpor,
            balance
        );

        require(
            toleratedQuoteValue != 0 && quoteValue <= toleratedQuoteValue,
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
            bosStruct.openingFeeLPValue,
            bosStruct.openingFeeTreasuryValue
        );

        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapReceiveFixed(
            newSwap,
            _getIporPublicationFeeAmount()
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
            utilizationRate <= _getMaxLpUtilizationPercentage(),
            MiltonErrors.LP_UTILIZATION_EXCEEDED
        );

        require(
            utilizationRatePerLeg <= _getMaxLpUtilizationPerLegPercentage(),
            MiltonErrors.LP_UTILIZATION_PER_LEG_EXCEEDED
        );
    }

    function _emitOpenSwapEvent(
        uint256 newSwapId,
        uint256 wadTotalAmount,
        AmmTypes.NewSwap memory newSwap,
        MiltonTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 iporPublicationAmount
    ) internal {
        emit OpenSwap(
            newSwapId,
            newSwap.buyer,
            _asset,
            MiltonTypes.SwapDirection(direction),
            AmmTypes.OpenSwapMoney(
                wadTotalAmount,
                newSwap.collateral,
                newSwap.notionalAmount,
                newSwap.openingFeeLPValue,
                newSwap.openingFeeTreasuryValue,
                iporPublicationAmount,
                newSwap.liquidationDepositAmount
            ),
            newSwap.openTimestamp,
            newSwap.openTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator
        );
    }

    function _calculateSwapdicators(
        uint256 calculateTimestamp,
        uint256 notionalAmount,
        uint256 quoteValue
    ) internal view returns (MiltonTypes.IporSwapIndicator memory indicator) {
        IporTypes.AccruedIpor memory accruedIpor = _warren.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        require(accruedIpor.ibtPrice != 0, MiltonErrors.IBT_PRICE_CANNOT_BE_ZERO);

        indicator = MiltonTypes.IporSwapIndicator(
            accruedIpor.indexValue,
            accruedIpor.ibtPrice,
            IporMath.division(notionalAmount * Constants.D18, accruedIpor.ibtPrice),
            quoteValue
        );
    }

    function _closeSwapPayFixed(uint256 swapId, uint256 closeTimestamp) internal {
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
            _getIncomeFeePercentage(),
            _getMinPercentagePositionValueWhenClosingBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        (
            uint256 transferredToBuyer,
            uint256 transferredToLiquidator
        ) = _transferTokensBasedOnPositionValue(
                iporSwap,
                positionValue,
                closeTimestamp,
                _getIncomeFeePercentage(),
                _getMinPercentagePositionValueWhenClosingBeforeMaturity(),
                _getSecondsBeforeMaturityWhenPositionCanBeClosed()
            );

        emit CloseSwap(
            swapId,
            _asset,
            closeTimestamp,
            msg.sender,
            transferredToBuyer,
            transferredToLiquidator
        );
    }

    function _closeSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) internal {
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
            _getIncomeFeePercentage(),
            _getMinPercentagePositionValueWhenClosingBeforeMaturity(),
            _getSecondsBeforeMaturityWhenPositionCanBeClosed()
        );

        (
            uint256 transferredToBuyer,
            uint256 transferredToLiquidator
        ) = _transferTokensBasedOnPositionValue(
                iporSwap,
                positionValue,
                closeTimestamp,
                _getIncomeFeePercentage(),
                _getMinPercentagePositionValueWhenClosingBeforeMaturity(),
                _getSecondsBeforeMaturityWhenPositionCanBeClosed()
            );

        emit CloseSwap(
            swapId,
            _asset,
            closeTimestamp,
            msg.sender,
            transferredToBuyer,
            transferredToLiquidator
        );
    }

    function _closeSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp) internal {
        require(swapIds.length > 0, MiltonErrors.SWAP_IDS_ARRAY_IS_EMPTY);

        for (uint256 i = 0; i < swapIds.length; i++) {
            _closeSwapPayFixed(swapIds[i], closeTimestamp);
        }
    }

    function _closeSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp) internal {
        require(swapIds.length > 0, MiltonErrors.SWAP_IDS_ARRAY_IS_EMPTY);

        for (uint256 i = 0; i < swapIds.length; i++) {
            _closeSwapReceiveFixed(swapIds[i], closeTimestamp);
        }
    }

    function _transferTokensBasedOnPositionValue(
        IporTypes.IporSwapMemory memory derivativeItem,
        int256 positionValue,
        uint256 _calculationTimestamp,
        uint256 cfgIncomeFeePercentage,
        uint256 cfgMinPercentagePositionValueToCloseBeforeMaturity,
        uint256 cfgSecondsBeforeMaturityWhenPositionCanBeClosed
    ) internal returns (uint256 transferredToBuyer, uint256 transferredToLiquidator) {
        uint256 absPositionValue = IporMath.absoluteValue(positionValue);
        uint256 minPositionValueToCloseBeforeMaturity = IporMath.percentOf(
            derivativeItem.collateral,
            cfgMinPercentagePositionValueToCloseBeforeMaturity
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
            (transferredToBuyer, transferredToLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral +
                    absPositionValue -
                    IporMath.division(absPositionValue * cfgIncomeFeePercentage, Constants.D18)
            );
        } else {
            //Milton earn, Trader looseMiltonStorage
            (transferredToBuyer, transferredToLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral - absPositionValue
            );
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount
    ) internal returns (uint256 transferredToBuyer, uint256 transferredToLiquidator) {
        uint256 decimals = _getDecimals();

        if (msg.sender == buyer) {
            transferAmount = transferAmount + liquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from Milton to Liquidator
            uint256 liqDepositAmountAssetDecimals = IporMath.convertWadToAssetDecimals(
                liquidationDepositAmount,
                decimals
            );
            IERC20Upgradeable(_asset).safeTransfer(msg.sender, liqDepositAmountAssetDecimals);
            transferredToLiquidator = IporMath.convertToWad(
                liqDepositAmountAssetDecimals,
                decimals
            );
        }

        if (transferAmount != 0) {
            uint256 transferAmmountAssetDecimals = IporMath.convertWadToAssetDecimals(
                transferAmount,
                decimals
            );
            //transfer from Milton to Trader
            IERC20Upgradeable(_asset).safeTransfer(buyer, transferAmmountAssetDecimals);

            transferredToBuyer = IporMath.convertToWad(transferAmmountAssetDecimals, decimals);
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
