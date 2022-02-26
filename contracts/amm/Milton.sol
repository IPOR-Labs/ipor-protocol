// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../libraries/types/DataTypes.sol";
import "../libraries/IporMath.sol";
import "../security/IporOwnableUpgradeable.sol";
import {IporErrors} from "../IporErrors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "./MiltonStorage.sol";
import "../configuration/MiltonConfiguration.sol";
import "../interfaces/IMiltonEvents.sol";
import "../tokenization/IpToken.sol";
import "../interfaces/IIporVault.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IJoseph.sol";

import "hardhat/console.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
//TODO: add pausable modifier for methodds
contract Milton is
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    MiltonConfiguration,
    IMiltonEvents,
    IMilton
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for DataTypes.IporSwapMemory;

    modifier onlyPublicationFeeTransferer() {
        require(
            msg.sender ==
                _iporConfiguration.getMiltonPublicationFeeTransferer(),
            IporErrors.MILTON_CALLER_NOT_MILTON_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    function initialize(
        address asset,
        address ipToken,
        address warren,
        address miltonStorage,
        address miltonSpreadModel,
        address initialIporConfiguration,
        address iporAssetConfigurationAddr,
        address iporVault
    ) public initializer {
        __Ownable_init();
        require(address(asset) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(ipToken) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(warren) != address(0), IporErrors.WRONG_ADDRESS);
        require(address(miltonStorage) != address(0), IporErrors.WRONG_ADDRESS);
        require(
            address(miltonSpreadModel) != address(0),
            IporErrors.WRONG_ADDRESS
        );
        require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
        _iporAssetConfiguration = IIporAssetConfiguration(
            iporAssetConfigurationAddr
        );

        _decimals = ERC20Upgradeable(asset).decimals();
        _miltonStorage = IMiltonStorage(miltonStorage);
        _miltonSpreadModel = IMiltonSpreadModel(miltonSpreadModel);
        _warren = IWarren(warren);
        _ipToken = IIpToken(ipToken);
        _asset = asset;
        _iporVault = IIporVault(iporVault);
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function depositToVault(uint256 assetValue)
        external
        nonReentrant
        returns (uint256 currentInterest)
    {        
        currentInterest = _iporVault.deposit(assetValue);
        _miltonStorage.incrementLiquidityPoolBalance(currentInterest);        
    }

    function withdrawFromVault(uint256 ivTokenValue)
        external
        nonReentrant
        returns (uint256 withdrawAssetValue, uint256 currentInterest)
    {
        (withdrawAssetValue, currentInterest) = _iporVault.withdraw(
            ivTokenValue
        );
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function setupMaxAllowance(address spender)
        external
        override
        onlyOwner
        whenNotPaused
    {
        IERC20Upgradeable(_asset).safeIncreaseAllowance(
            spender,
            Constants.MAX_VALUE
        );
    }

    //@notice transfer publication fee to configured charlie treasurer address
    function transferPublicationFee(uint256 amount)
        external
        onlyPublicationFeeTransferer
        nonReentrant
    {
        address charlieTreasurer = _iporAssetConfiguration
            .getCharlieTreasurer();
        require(
            address(0) != charlieTreasurer,
            IporErrors.MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS
        );

        _miltonStorage.updateStorageWhenTransferPublicationFee(amount);

        IERC20Upgradeable(_asset).safeTransfer(charlieTreasurer, amount);
    }

    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external override nonReentrant returns (uint256) {
        return
            _openSwapPayFixed(
                block.timestamp,
                totalAmount,
                maximumSlippage,
                collateralizationFactor
            );
    }

    function openSwapReceiveFixed(
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external override nonReentrant returns (uint256) {
        return
            _openSwapReceiveFixed(
                block.timestamp,
                totalAmount,
                maximumSlippage,
                collateralizationFactor
            );
    }

    function closeSwapPayFixed(uint256 swapId) external override nonReentrant {
        _closeSwapPayFixed(swapId, block.timestamp);
    }

    function closeSwapReceiveFixed(uint256 swapId)
        external
        override
        nonReentrant
    {
        _closeSwapReceiveFixed(swapId, block.timestamp);
    }

    function calculateSpread()
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        (spreadPayFixedValue, spreadRecFixedValue) = _calculateSpread(
            block.timestamp
        );
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
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _calculateSoap(
            block.timestamp
        );
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function calculateSwapPayFixedValue(DataTypes.IporSwapMemory memory swap)
        external
        view
        override
        returns (int256)
    {
        return _calculateSwapPayFixedValue(block.timestamp, swap);
    }

    function calculateSwapReceiveFixedValue(
        DataTypes.IporSwapMemory memory swap
    ) external view override returns (int256) {
        return _calculateSwapReceiveFixedValue(block.timestamp, swap);
    }

    //TODO: refactor in this way that timestamp is not visible in external milton method
    function calculateExchangeRate(uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        (, , int256 soap) = _calculateSoap(calculateTimestamp);

        int256 balance = _getAccruedBalance().liquidityPool.toInt256() - soap;

        require(
            balance >= 0,
            IporErrors.JOSEPH_SOAP_AND_MILTON_LP_BALANCE_SUM_IS_TOO_LOW
        );
        uint256 ipTokenTotalSupply = _ipToken.totalSupply();
        if (ipTokenTotalSupply != 0) {
            return
                IporMath.division(
                    balance.toUint256() * Constants.D18,
                    ipTokenTotalSupply
                );
        } else {
            return Constants.D18;
        }
    }

    function getAccruedBalance()
        external
        view
        override
        returns (DataTypes.MiltonBalanceMemory memory)
    {
        return _getAccruedBalance();
    }

    function _getAccruedBalance()
        internal
        view
        returns (DataTypes.MiltonBalanceMemory memory)
    {
        DataTypes.MiltonBalanceMemory memory accruedBalance = _miltonStorage
            .getBalance();
        accruedBalance.liquidityPool =
            accruedBalance.liquidityPool +
            _iporVault.getCurrentInterest();
        return accruedBalance;
    }

    function _calculateSwapPayFixedValue(
        uint256 timestamp,
        DataTypes.IporSwapMemory memory swap
    ) internal view returns (int256) {
        DataTypes.IporSwapInterest memory derivativeInterest = swap
            .calculateInterestForSwapPayFixed(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );
        //TODO: remove dublicates
        if (derivativeInterest.positionValue > 0) {
            if (derivativeInterest.positionValue < swap.collateral.toInt256()) {
                return derivativeInterest.positionValue;
            } else {
                return swap.collateral.toInt256();
            }
        } else {
            if (
                derivativeInterest.positionValue < -swap.collateral.toInt256()
            ) {
                return -swap.collateral.toInt256();
            } else {
                return derivativeInterest.positionValue;
            }
        }
    }

    function _calculateSwapReceiveFixedValue(
        uint256 timestamp,
        DataTypes.IporSwapMemory memory swap
    ) internal view returns (int256) {
        DataTypes.IporSwapInterest memory derivativeInterest = swap
            .calculateInterestForSwapReceiveFixed(
                timestamp,
                _warren.calculateAccruedIbtPrice(_asset, timestamp)
            );

        if (derivativeInterest.positionValue > 0) {
            if (derivativeInterest.positionValue < swap.collateral.toInt256()) {
                return derivativeInterest.positionValue;
            } else {
                return swap.collateral.toInt256();
            }
        } else {
            if (
                derivativeInterest.positionValue < -swap.collateral.toInt256()
            ) {
                return -swap.collateral.toInt256();
            } else {
                return derivativeInterest.positionValue;
            }
        }
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
            _miltonStorage.calculateSoapPayFixed(
                accruedIpor.ibtPrice,
                calculateTimestamp
            ),
            accruedIpor,
            balance
        );
        spreadRecFixedValue = _miltonSpreadModel.calculateSpreadRecFixed(
            _miltonStorage.calculateSoapReceiveFixed(
                accruedIpor.ibtPrice,
                calculateTimestamp
            ),
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
        uint256 accruedIbtPrice = _warren.calculateAccruedIbtPrice(
            _asset,
            calculateTimestamp
        );
        (int256 _soapPf, int256 _soapRf, int256 _soap) = _miltonStorage
            .calculateSoap(accruedIbtPrice, calculateTimestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _beforeOpenSwap(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal view returns (DataTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(
            maximumSlippage != 0,
            IporErrors.MILTON_MAXIMUM_SLIPPAGE_TOO_LOW
        );
        require(totalAmount != 0, IporErrors.MILTON_TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20Upgradeable(_asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.MILTON_ASSET_BALANCE_OF_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, _decimals);

        require(
            collateralizationFactor >= _getMinCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_LOW
        );
        require(
            collateralizationFactor <= _getMaxCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH
        );

        require(
            wadTotalAmount >
                _getLiquidationDepositAmount() + _getIporPublicationFeeAmount(),
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        require(
            maximumSlippage <= _getMaxSlippagePercentage(),
            IporErrors.MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH
        );

        (
            uint256 collateral,
            uint256 notional,
            uint256 openingFee
        ) = _calculateDerivativeAmount(
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
                _getLiquidationDepositAmount() +
                    _getIporPublicationFeeAmount() +
                    openingFee,
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

    function _openSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            maximumSlippage,
            collateralizationFactor
        );

        DataTypes.MiltonBalanceMemory memory balance = _getAccruedBalance();
        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFee;
        balance.payFixedSwaps = balance.payFixedSwaps + bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.payFixedSwaps
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuotePayFixed(
            _miltonStorage.calculateSoapPayFixed(
                bosStruct.accruedIpor.ibtPrice,
                openTimestamp
            ),
            bosStruct.accruedIpor,
            balance
        );

        DataTypes.IporSwapIndicator
            memory indicator = _calculateDerivativeIndicators(
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

        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );

        _emitOpenSwapEvent(
            newSwapId,
            newSwap,
            indicator,
            0,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount,
            quoteValue
        );

        return newSwapId;
    }

    function _openSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            maximumSlippage,
            collateralizationFactor
        );

        DataTypes.MiltonBalanceMemory memory balance = _getAccruedBalance();

        balance.liquidityPool = balance.liquidityPool + bosStruct.openingFee;
        balance.receiveFixedSwaps =
            balance.receiveFixedSwaps +
            bosStruct.collateral;

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.receiveFixedSwaps
        );

        uint256 quoteValue = _miltonSpreadModel.calculateQuoteReceiveFixed(
            _miltonStorage.calculateSoapReceiveFixed(
                bosStruct.accruedIpor.ibtPrice,
                openTimestamp
            ),
            bosStruct.accruedIpor,
            balance
        );

        DataTypes.IporSwapIndicator
            memory indicator = _calculateDerivativeIndicators(
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

        uint256 newSwapId = _miltonStorage
            .updateStorageWhenOpenSwapReceiveFixed(
                newSwap,
                bosStruct.openingFee,
                _getLiquidationDepositAmount(),
                _getIporPublicationFeeAmount(),
                _getOpeningFeeForTreasuryPercentage()
            );

        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            totalAmount
        );

        _emitOpenSwapEvent(
            newSwapId,
            newSwap,
            indicator,
            1,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount,
            quoteValue
        );

        return newSwapId;
    }

    function _validateLiqudityPoolUtylization(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralPerLegBalance
    ) internal pure {
        uint256 utilizationRate;

        if (totalLiquidityPoolBalance != 0) {
            utilizationRate = IporMath.division(
                totalCollateralPerLegBalance * Constants.D18,
                totalLiquidityPoolBalance
            );
        } else {
            utilizationRate = Constants.MAX_VALUE;
        }

        require(
            utilizationRate <= _getMaxLpUtilizationPerLegPercentage(),
            IporErrors.MILTON_LIQUIDITY_POOL_UTILIZATION_EXCEEDED
        );
    }

    function _emitOpenSwapEvent(
        uint256 newSwapId,
        DataTypes.NewSwap memory newSwap,
        DataTypes.IporSwapIndicator memory indicator,
        uint256 direction,
        uint256 openingAmount,
        uint256 iporPublicationAmount,
        uint256 quoteValue
    ) internal {
        //TODO: add openingAmount to event and check in tests
        //TODO: add iporPublicationAmount to event and check in test
        //TODO: add quoteValue to event and check in test
        emit OpenSwap(
            newSwapId,
            newSwap.buyer,
            _asset,
            DataTypes.SwapDirection(direction),
            newSwap.collateral,
            newSwap.liquidationDepositAmount,
            newSwap.notionalAmount,
            newSwap.startingTimestamp,
            newSwap.startingTimestamp +
                Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator,
            openingAmount,
            iporPublicationAmount,
            quoteValue
        );
    }

    function _calculateDerivativeIndicators(
        uint256 calculateTimestamp,
        uint256 notionalAmount,
        uint256 quoteValue
    ) internal view returns (DataTypes.IporSwapIndicator memory indicator) {
        DataTypes.AccruedIpor memory accruedIpor = _warren.getAccruedIndex(
            calculateTimestamp,
            _asset
        );

        require(
            accruedIpor.ibtPrice != 0,
            IporErrors.MILTON_IBT_PRICE_CANNOT_BE_ZERO
        );

        indicator = DataTypes.IporSwapIndicator(
            accruedIpor.indexValue,
            accruedIpor.ibtPrice,
            IporMath.division(
                notionalAmount * Constants.D18,
                accruedIpor.ibtPrice
            ),
            quoteValue
        );
    }

    function _closeSwapPayFixed(uint256 swapId, uint256 closeTimestamp)
        internal
    {
        require(
            swapId != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_SWAP_ID
        );

        DataTypes.IporSwapMemory memory iporSwap = _miltonStorage
            .getSwapPayFixed(swapId);

        require(
            iporSwap.state == uint256(DataTypes.SwapState.ACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        uint256 incomeTaxPercentage = _getIncomeTaxPercentage();

        int256 positionValue = _calculateSwapPayFixedValue(
            closeTimestamp,
            iporSwap
        );

        _miltonStorage.updateStorageWhenCloseSwapPayFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeTaxPercentage()
        );

        _transferTokensBasedOnPositionValue(
            iporSwap,
            positionValue,
            closeTimestamp,
            incomeTaxPercentage
        );

        emit CloseSwap(swapId, _asset, closeTimestamp);
    }

    function _closeSwapReceiveFixed(uint256 swapId, uint256 closeTimestamp)
        internal
    {
        require(
            swapId != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_SWAP_ID
        );

        DataTypes.IporSwapMemory memory iporSwap = _miltonStorage
            .getSwapReceiveFixed(swapId);

        require(
            iporSwap.state == uint256(DataTypes.SwapState.ACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        int256 positionValue = _calculateSwapReceiveFixedValue(
            closeTimestamp,
            iporSwap
        );

        _miltonStorage.updateStorageWhenCloseSwapReceiveFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeTaxPercentage()
        );

        _transferTokensBasedOnPositionValue(
            iporSwap,
            positionValue,
            closeTimestamp,
            _getIncomeTaxPercentage()
        );

        emit CloseSwap(swapId, _asset, closeTimestamp);
    }

    function _transferTokensBasedOnPositionValue(
        DataTypes.IporSwapMemory memory derivativeItem,
        int256 positionValue,
        uint256 _calculationTimestamp,
        uint256 incomeTaxPercentage
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        if (abspositionValue < derivativeItem.collateral) {
            //verify if sender is an owner of swap if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (msg.sender != derivativeItem.buyer) {
                require(
                    _calculationTimestamp >= derivativeItem.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        if (positionValue > 0) {
            //Trader earn, Milton loose
            _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral +
                    abspositionValue -
                    IporMath.division(
                        abspositionValue * incomeTaxPercentage,
                        Constants.D18
                    )
            );
        } else {
            //Milton earn, Trader looseMiltonStorage
            _transferDerivativeAmount(
                derivativeItem.buyer,
                derivativeItem.liquidationDepositAmount,
                derivativeItem.collateral - abspositionValue
            );
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(
        address buyer,
        uint256 liquidationDepositAmount,
        uint256 transferAmount
    ) internal {
        if (msg.sender == buyer) {
            transferAmount = transferAmount + liquidationDepositAmount;
        } else {
            //transfer liquidation deposit amount from Milton to Sender
            IERC20Upgradeable(_asset).safeTransfer(
                msg.sender,
                IporMath.convertWadToAssetDecimals(
                    liquidationDepositAmount,
                    _decimals
                )
            );
        }

        if (transferAmount != 0) {
            //transfer from Milton to Trader
            IERC20Upgradeable(_asset).safeTransfer(
                buyer,
                IporMath.convertWadToAssetDecimals(transferAmount, _decimals)
            );
        }
    }

    function _calculateDerivativeAmount(
        uint256 totalAmount,
        uint256 collateralizationFactor,
        uint256 liquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeePercentage
    )
        internal
        pure
        returns (
            uint256 collateral,
            uint256 notional,
            uint256 openingFee
        )
    {
        collateral = IporMath.division(
            (totalAmount -
                liquidationDepositAmount -
                iporPublicationFeeAmount) * Constants.D18,
            Constants.D18 +
                IporMath.division(
                    collateralizationFactor * openingFeePercentage,
                    Constants.D18
                )
        );
        notional = IporMath.division(
            collateralizationFactor * collateral,
            Constants.D18
        );
        openingFee = IporMath.division(
            notional * openingFeePercentage,
            Constants.D18
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
