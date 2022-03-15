// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/IporMath.sol";
import {IporErrors} from "../IporErrors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "./MiltonStorage.sol";
import "../configuration/MiltonConfiguration.sol";
import "../tokenization/IpToken.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IJoseph.sol";

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
    using IporSwapLogic for DataTypes.IporSwapMemory;

    modifier onlyJoseph() {
        require(msg.sender == _joseph, IporErrors.MILTON_CALLER_NOT_JOSEPH);
        _;
    }

    function initialize(
        address asset,
        address ipToken,
        address warren,
        address miltonStorage,
        address miltonSpreadModel,
        address stanley
    ) public initializer {
        console.log("ERC20Upgradeable(asset).decimals()", ERC20Upgradeable(asset).decimals());
        console.log("_getDecimals()", _getDecimals());
        __Ownable_init();
        require(address(asset) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(ipToken) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(warren) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(miltonStorage) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(miltonSpreadModel) != address(0), IporErrors.WRONG_ADDRESS);
        require(_getDecimals() == ERC20Upgradeable(asset).decimals(), IporErrors.WRONG_DECIMALS);

        _miltonStorage = IMiltonStorage(miltonStorage);
        _miltonSpreadModel = IMiltonSpreadModel(miltonSpreadModel);
        _warren = IWarren(warren);
        _ipToken = IIpToken(ipToken);
        _asset = asset;
        _stanley = IStanley(stanley);
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getAccruedBalance()
        external
        view
        override
        returns (DataTypes.MiltonBalanceMemory memory)
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

    function calculateExchangeRate(uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        (, , int256 soap) = _calculateSoap(calculateTimestamp);

        int256 balance = _getAccruedBalance().liquidityPool.toInt256() - soap;

        require(balance >= 0, IporErrors.MILTON_SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW);

        uint256 ipTokenTotalSupply = _ipToken.totalSupply();

        if (ipTokenTotalSupply != 0) {
            return IporMath.division(balance.toUint256() * Constants.D18, ipTokenTotalSupply);
        } else {
            return Constants.D18;
        }
    }

    function calculateSwapPayFixedValue(DataTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapPayFixedValue(block.timestamp, swap);
    }

    function calculateSwapReceiveFixedValue(DataTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapReceiveFixedValue(block.timestamp, swap);
    }

    //@param totalAmount underlying tokens transfered from buyer to Milton, represented in decimals specific for asset
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 collateralizationFactor
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return
            _openSwapPayFixed(
                block.timestamp,
                totalAmount,
                toleratedQuoteValue,
                collateralizationFactor
            );
    }

    //@param totalAmount underlying tokens transfered from buyer to Milton, represented in decimals specific for asset
    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 collateralizationFactor
    ) external override nonReentrant whenNotPaused returns (uint256) {
        return
            _openSwapReceiveFixed(
                block.timestamp,
                totalAmount,
                toleratedQuoteValue,
                collateralizationFactor
            );
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
        onlyJoseph
        nonReentrant
        whenNotPaused
    {
        (uint256 withdrawnValue, uint256 vaultBalance) = _stanley.withdraw(assetValue);
        _miltonStorage.updateStorageWhenWithdrawFromStanley(withdrawnValue, vaultBalance);
    }

    function withdrawAllFromStanley() external onlyJoseph nonReentrant whenNotPaused {
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

    function _getAccruedBalance() internal view returns (DataTypes.MiltonBalanceMemory memory) {
        DataTypes.MiltonBalanceMemory memory accruedBalance = _miltonStorage.getBalance();
        uint256 actualVaultBalance = _stanley.totalBalance(address(this));
        accruedBalance.liquidityPool =
            accruedBalance.liquidityPool +
            (actualVaultBalance - accruedBalance.vault);
        accruedBalance.vault = actualVaultBalance;
        return accruedBalance;
    }

    function _calculateSwapPayFixedValue(uint256 timestamp, DataTypes.IporSwapMemory memory swap)
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
        DataTypes.IporSwapMemory memory swap
    ) internal view returns (int256) {
        return
            swap.calculateSwapReceiveFixedValue(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );
    }

    function _calculateIncomeTaxValue(int256 positionValue) internal pure returns (uint256) {
        return
            IporMath.division(
                IporMath.absoluteValue(positionValue) * _getIncomeTaxPercentage(),
                Constants.D18
            );
    }

    function _calculateSpread(uint256 calculateTimestamp)
        internal
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        DataTypes.AccruedIpor memory accruedIpor = _warren.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        DataTypes.MiltonBalanceMemory memory balance = _getAccruedBalance();

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
        uint256 collateralizationFactor
    ) internal view returns (DataTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(totalAmount != 0, IporErrors.MILTON_TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20Upgradeable(_asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.ASSET_BALANCE_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, _getDecimals());

        require(
            collateralizationFactor >= _getMinCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_LOW
        );
        require(
            collateralizationFactor <= _getMaxCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH
        );

        require(
            wadTotalAmount > _getLiquidationDepositAmount() + _getIporPublicationFeeAmount(),
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        (uint256 collateral, uint256 notional, uint256 openingFee) = IporSwapLogic
            .calculateSwapAmount(
                wadTotalAmount,
                collateralizationFactor,
                _getLiquidationDepositAmount(),
                _getIporPublicationFeeAmount(),
                _getOpeningFeePercentage()
            );

        require(
            collateral <= _getMaxSwapCollateralAmount(),
            IporErrors.MILTON_COLLATERAL_AMOUNT_TOO_HIGH
        );

        require(
            wadTotalAmount >
                _getLiquidationDepositAmount() + _getIporPublicationFeeAmount() + openingFee,
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        return
            DataTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFee,
                _getLiquidationDepositAmount(),
                _getIporPublicationFeeAmount(),
                _warren.getAccruedIndex(openTimestamp, _asset)
            );
    }

    //@param totalAmount underlying tokens transfered from buyer to Milton, represented in decimals specific for asset
    function _openSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 collateralizationFactor
    ) internal returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            collateralizationFactor
        );

        DataTypes.MiltonBalanceMemory memory balance = _getAccruedBalance();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFee;
        balance.payFixedSwaps = balance.payFixedSwaps + bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.payFixedSwaps,
            balance.payFixedSwaps + balance.receiveFixedSwaps
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuotePayFixed(
            _miltonStorage.calculateSoapPayFixed(bosStruct.accruedIpor.ibtPrice, openTimestamp),
            bosStruct.accruedIpor,
            balance
        );

        require(
            toleratedQuoteValue != 0 && quoteValue <= toleratedQuoteValue,
            IporErrors.TOLERATED_QUOTE_VALUE_EXCEEDED
        );

        DataTypes.IporSwapIndicator memory indicator = _calculateSwapdicators(
            openTimestamp,
            bosStruct.notional,
            quoteValue
        );

        DataTypes.NewSwap memory newSwap = DataTypes.NewSwap(
            msg.sender,
            openTimestamp,
            bosStruct.collateral,
            bosStruct.liquidationDepositAmount,
            bosStruct.notional,
            indicator.fixedInterestRate,
            indicator.ibtQuantity
        );

        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapPayFixed(
            newSwap,
            bosStruct.openingFee,
            _getLiquidationDepositAmount(),
            _getIporPublicationFeeAmount(),
            _getOpeningFeeForTreasuryPercentage()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), totalAmount);

        _emitOpenSwapEvent(
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            0,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount
        );

        return newSwapId;
    }

    //@param totalAmount underlying tokens transfered from buyer to Milton, represented in decimals specific for asset
    function _openSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 toleratedQuoteValue,
        uint256 collateralizationFactor
    ) internal returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            collateralizationFactor
        );

        DataTypes.MiltonBalanceMemory memory balance = _getAccruedBalance();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFee;
        balance.receiveFixedSwaps = balance.receiveFixedSwaps + bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.receiveFixedSwaps,
            balance.payFixedSwaps + balance.receiveFixedSwaps
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuoteReceiveFixed(
            _miltonStorage.calculateSoapReceiveFixed(bosStruct.accruedIpor.ibtPrice, openTimestamp),
            bosStruct.accruedIpor,
            balance
        );

        require(
            toleratedQuoteValue != 0 && quoteValue <= toleratedQuoteValue,
            IporErrors.TOLERATED_QUOTE_VALUE_EXCEEDED
        );

        DataTypes.IporSwapIndicator memory indicator = _calculateSwapdicators(
            openTimestamp,
            bosStruct.notional,
            quoteValue
        );

        DataTypes.NewSwap memory newSwap = DataTypes.NewSwap(
            msg.sender,
            openTimestamp,
            bosStruct.collateral,
            bosStruct.liquidationDepositAmount,
            bosStruct.notional,
            indicator.fixedInterestRate,
            indicator.ibtQuantity
        );

        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapReceiveFixed(
            newSwap,
            bosStruct.openingFee,
            _getLiquidationDepositAmount(),
            _getIporPublicationFeeAmount(),
            _getOpeningFeeForTreasuryPercentage()
        );

        IERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), totalAmount);

        _emitOpenSwapEvent(
            newSwapId,
            bosStruct.wadTotalAmount,
            newSwap,
            indicator,
            1,
            bosStruct.openingFee,
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
            IporErrors.MILTON_LP_UTILIZATION_EXCEEDED
        );

        require(
            utilizationRatePerLeg <= _getMaxLpUtilizationPerLegPercentage(),
            IporErrors.MILTON_LP_UTILIZATION_PER_LEG_EXCEEDED
        );
    }

    function _emitOpenSwapEvent(
        uint256 newSwapId,
        uint256 wadTotalAmount,
        DataTypes.NewSwap memory newSwap,
        DataTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 openingAmount,
        uint256 iporPublicationAmount
    ) internal {
        emit OpenSwap(
            newSwapId,
            newSwap.buyer,
            _asset,
            DataTypes.SwapDirection(direction),
            DataTypes.OpenSwapMoney(
                wadTotalAmount,
                newSwap.collateral,
                newSwap.notionalAmount,
                openingAmount,
                iporPublicationAmount,
                newSwap.liquidationDepositAmount
            ),
            newSwap.startingTimestamp,
            newSwap.startingTimestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator
        );
    }

    function _calculateSwapdicators(
        uint256 calculateTimestamp,
        uint256 notionalAmount,
        uint256 quoteValue
    ) internal view returns (DataTypes.IporSwapIndicator memory indicator) {
        DataTypes.AccruedIpor memory accruedIpor = _warren.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        require(accruedIpor.ibtPrice != 0, IporErrors.MILTON_IBT_PRICE_CANNOT_BE_ZERO);

        indicator = DataTypes.IporSwapIndicator(
            accruedIpor.indexValue,
            accruedIpor.ibtPrice,
            IporMath.division(notionalAmount * Constants.D18, accruedIpor.ibtPrice),
            quoteValue
        );
    }

    function _closeSwapPayFixed(uint256 swapId, uint256 closeTimestamp) internal {
        require(swapId != 0, IporErrors.MILTON_INCORRECT_SWAP_ID);

        DataTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapPayFixed(swapId);

        require(
            iporSwap.state == uint256(DataTypes.SwapState.ACTIVE),
            IporErrors.MILTON_INCORRECT_SWAP_STATUS
        );

        uint256 incomeTaxPercentage = _getIncomeTaxPercentage();

        int256 positionValue = _calculateSwapPayFixedValue(closeTimestamp, iporSwap);

        _miltonStorage.updateStorageWhenCloseSwapPayFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeTaxPercentage()
        );

        (
            uint256 transferedToBuyer,
            uint256 transferedToLiquidator
        ) = _transferTokensBasedOnPositionValue(
                iporSwap,
                positionValue,
                closeTimestamp,
                incomeTaxPercentage
            );

        emit CloseSwap(
            swapId,
            _asset,
            closeTimestamp,
            msg.sender,
            transferedToBuyer,
            transferedToLiquidator
        );
    }

    function _closeSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp) internal {
        require(swapId != 0, IporErrors.MILTON_INCORRECT_SWAP_ID);

        DataTypes.IporSwapMemory memory iporSwap = _miltonStorage.getSwapReceiveFixed(swapId);

        require(
            iporSwap.state == uint256(DataTypes.SwapState.ACTIVE),
            IporErrors.MILTON_INCORRECT_SWAP_STATUS
        );

        int256 positionValue = _calculateSwapReceiveFixedValue(closeTimestamp, iporSwap);

        _miltonStorage.updateStorageWhenCloseSwapReceiveFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeTaxPercentage()
        );

        (
            uint256 transferedToBuyer,
            uint256 transferedToLiquidator
        ) = _transferTokensBasedOnPositionValue(
                iporSwap,
                positionValue,
                closeTimestamp,
                _getIncomeTaxPercentage()
            );

        emit CloseSwap(
            swapId,
            _asset,
            closeTimestamp,
            msg.sender,
            transferedToBuyer,
            transferedToLiquidator
        );
    }

    function _closeSwapsPayFixed(uint256[] memory swapIds, uint256 closeTimestamp) internal {
        require(swapIds.length > 0, IporErrors.MILTON_SWAP_IDS_ARRAY_IS_EMPTY);

        for (uint256 i = 0; i < swapIds.length; i++) {
            _closeSwapPayFixed(swapIds[i], closeTimestamp);
        }
    }

    function _closeSwapsReceiveFixed(uint256[] memory swapIds, uint256 closeTimestamp) internal {
        require(swapIds.length > 0, IporErrors.MILTON_SWAP_IDS_ARRAY_IS_EMPTY);

        for (uint256 i = 0; i < swapIds.length; i++) {
            _closeSwapReceiveFixed(swapIds[i], closeTimestamp);
        }
    }

    function _transferTokensBasedOnPositionValue(
        DataTypes.IporSwapMemory memory derivativeItem,
        int256 positionValue,
        uint256 _calculationTimestamp,
        uint256 incomeTaxPercentage
    ) internal returns (uint256 transferedToBuyer, uint256 transferedToLiquidator) {
        uint256 absPositionValue = IporMath.absoluteValue(positionValue);

        if (absPositionValue < derivativeItem.collateral) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (msg.sender != derivativeItem.buyer) {
                require(
                    _calculationTimestamp >= derivativeItem.endingTimestamp,
                    IporErrors.MILTON_CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_AND_NO_MATURITY
                );
            }
        }

        if (positionValue > 0) {
            //Trader earn, Milton loose
            (transferedToBuyer, transferedToLiquidator) = _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral +
                    absPositionValue -
                    IporMath.division(absPositionValue * incomeTaxPercentage, Constants.D18)
            );
        } else {
            //Milton earn, Trader looseMiltonStorage
            (transferedToBuyer, transferedToLiquidator) = _transferDerivativeAmount(
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
    ) internal returns (uint256 transferedToBuyer, uint256 transferedToLiquidator) {
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
            transferedToLiquidator = IporMath.convertToWad(liqDepositAmountAssetDecimals, decimals);
        }

        if (transferAmount != 0) {
            uint256 transferAmmountAssetDecimals = IporMath.convertWadToAssetDecimals(
                transferAmount,
                decimals
            );
            //transfer from Milton to Trader
            IERC20Upgradeable(_asset).safeTransfer(buyer, transferAmmountAssetDecimals);

            transferedToBuyer = IporMath.convertToWad(transferAmmountAssetDecimals, decimals);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
