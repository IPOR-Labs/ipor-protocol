// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/IporMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IporErrors} from "../IporErrors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import "../interfaces/IWarren.sol";
import "../oracles/WarrenStorage.sol";
import "./MiltonStorage.sol";
import "../interfaces/IMiltonEvents.sol";
import "../tokenization/IpToken.sol";

import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonLiquidityPoolUtilizationModel.sol";
import "../interfaces/IMiltonSpreadModel.sol";
import "../interfaces/IJoseph.sol";

/**
 * @title Milton - Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
//TODO: add pausable modifier for methodds
contract Milton is Ownable, Pausable, ReentrancyGuard, IMiltonEvents, IMilton {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using IporSwapLogic for DataTypes.IporSwapMemory;

    uint8 private immutable _decimals;
    address private immutable _asset;
    IIpToken private immutable _ipToken;
    IWarren internal immutable _warren;

    IMiltonStorage internal immutable _miltonStorage;
    IMiltonSpreadModel internal immutable _miltonSpreadModel;
    IIporConfiguration internal immutable _iporConfiguration;
    IIporAssetConfiguration internal immutable _iporAssetConfiguration;

    constructor(address asset, address initialIporConfiguration) {
        require(address(asset) != address(0), IporErrors.WRONG_ADDRESS);
        require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
        require(
            _iporConfiguration.assetSupported(asset) == 1,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        address iporAssetConfigurationAddr = _iporConfiguration
            .getIporAssetConfiguration(asset);

        require(
            address(iporAssetConfigurationAddr) != address(0),
            IporErrors.WRONG_ADDRESS
        );

        _iporAssetConfiguration = IIporAssetConfiguration(
            iporAssetConfigurationAddr
        );

        _decimals = _iporAssetConfiguration.getDecimals();
        _miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );
        _miltonSpreadModel = IMiltonSpreadModel(
            _iporConfiguration.getMiltonSpreadModel()
        );
        _warren = IWarren(_iporConfiguration.getWarren());
        _ipToken = IIpToken(_iporAssetConfiguration.getIpToken());
        _asset = asset;
    }

    modifier onlyActiveSwapPayFixed(uint256 swapId) {
        require(
            _miltonStorage.getSwapPayFixedState(swapId) == 1,
            IporErrors.MILTON_DERIVATIVE_IS_INACTIVE
        );
        _;
    }

    modifier onlyActiveSwapReceiveFixed(uint256 swapId) {
        require(
            _miltonStorage.getSwapReceiveFixedState(swapId) == 0,
            IporErrors.MILTON_DERIVATIVE_IS_INACTIVE
        );
        _;
    }

    modifier onlyPublicationFeeTransferer() {
        require(
            msg.sender ==
                _iporConfiguration.getMiltonPublicationFeeTransferer(),
            IporErrors.MILTON_CALLER_NOT_MILTON_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    //    fallback() external payable  {
    //        require(msg.data.length == 0); emit LogDepositReceived(msg.sender);
    //    }

    function authorizeJoseph() external override onlyOwner whenNotPaused {
        IERC20(_asset).safeIncreaseAllowance(
            _iporAssetConfiguration.getJoseph(),
            Constants.MAX_VALUE
        );
    }

    //@notice transfer publication fee to configured charlie treasurer address
    function transferPublicationFee(uint256 amount)
        external
        onlyPublicationFeeTransferer
    {
        require(amount != 0, IporErrors.MILTON_NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        require(
            amount <= _miltonStorage.getBalance().openingFee,
            IporErrors.MILTON_NOT_ENOUGH_OPENING_FEE_BALANCE
        );
        address charlieTreasurer = _iporAssetConfiguration
            .getCharlieTreasurer();
        require(
            address(0) != charlieTreasurer,
            IporErrors.MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS
        );
        _miltonStorage.updateStorageWhenTransferPublicationFee(amount);
        //TODO: user Address from OZ and use call
        //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
        IERC20(_asset).safeTransfer(charlieTreasurer, amount);
    }

    //TODO: !!! consider connect configuration with milton storage,
    //in this way that if there is parameter used only in open and close position then let put it in miltonstorage
    function openSwapPayFixed(
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) external override returns (uint256) {
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
    ) external override returns (uint256) {
        return
            _openSwapReceiveFixed(
                block.timestamp,
                totalAmount,
                maximumSlippage,
                collateralizationFactor
            );
    }

    function closeSwapPayFixed(uint256 swapId)
        external
        override
        onlyActiveSwapPayFixed(swapId)
        nonReentrant
    {
        _closeSwapPayFixed(swapId, block.timestamp);
    }

    function closeSwapReceiveFixed(uint256 swapId)
        external
        override
        onlyActiveSwapReceiveFixed(swapId)
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

        int256 balance = _miltonStorage.getBalance().liquidityPool.toInt256() -
            soap;

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

        try
            _miltonSpreadModel.calculatePartialSpreadPayFixed(
                _miltonStorage,
                calculateTimestamp,
                accruedIpor
            )
        returns (uint256 _spreadPayFixedValue) {
            spreadPayFixedValue = _spreadPayFixedValue;
        } catch {
            spreadPayFixedValue = 0;
        }

        try
            _miltonSpreadModel.calculatePartialSpreadRecFixed(
                _miltonStorage,
                calculateTimestamp,
                accruedIpor
            )
        returns (uint256 _spreadRecFixedValue) {
            spreadRecFixedValue = _spreadRecFixedValue;
        } catch {
            spreadRecFixedValue = 0;
        }
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
        IIporAssetConfiguration iac = _iporAssetConfiguration;
        require(
            maximumSlippage != 0,
            IporErrors.MILTON_MAXIMUM_SLIPPAGE_TOO_LOW
        );
        require(totalAmount != 0, IporErrors.MILTON_TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20(_asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.MILTON_ASSET_BALANCE_OF_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, _decimals);

        require(
            collateralizationFactor >= iac.getMinCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_LOW
        );
        require(
            collateralizationFactor <= iac.getMaxCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH
        );

        require(
            wadTotalAmount >
                iac.getLiquidationDepositAmount() +
                    iac.getIporPublicationFeeAmount(),
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );
        require(
            wadTotalAmount <= iac.getMaxSwapTotalAmount(),
            IporErrors.MILTON_TOTAL_AMOUNT_TOO_HIGH
        );

        require(
            maximumSlippage <= iac.getMaxSlippagePercentage(),
            IporErrors.MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH
        );

        (
            uint256 collateral,
            uint256 notional,
            uint256 openingFee
        ) = _calculateDerivativeAmount(
                wadTotalAmount,
                collateralizationFactor,
                iac.getLiquidationDepositAmount(),
                iac.getIporPublicationFeeAmount(),
                iac.getOpeningFeePercentage()
            );

        require(
            wadTotalAmount >
                iac.getLiquidationDepositAmount() +
                    iac.getIporPublicationFeeAmount() +
                    openingFee,
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        return
            DataTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFee,
                iac.getLiquidationDepositAmount(),
                iac.getIporPublicationFeeAmount(),
                _warren.getAccruedIndex(openTimestamp, _asset)
            );
    }

    function _openSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal nonReentrant returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            maximumSlippage,
            collateralizationFactor
        );

        DataTypes.MiltonTotalBalanceMemory memory balance = _miltonStorage
            .getBalance();

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.payFixedSwaps,
            bosStruct.collateral,
            bosStruct.openingFee
        );

        uint256 spreadValue = _miltonSpreadModel.calculateSpreadPayFixed(
            _miltonStorage,
            openTimestamp,
            bosStruct.accruedIpor,
            bosStruct.collateral,
            bosStruct.openingFee
        );

        DataTypes.IporSwapIndicator
            memory indicator = _calculateDerivativeIndicators(
                openTimestamp,
                0,
                bosStruct.notional,
                spreadValue
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
        //TODO: pass to miltonStorage all required parameters, dont use iporassetconfiguration in milton storage at all
        uint256 newSwapId = _miltonStorage.updateStorageWhenOpenSwapPayFixed(
            newSwap,
            bosStruct.openingFee
        );

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        //TODO: sendValue z Address (use with ReentrancyGuard)
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), totalAmount);

        _emitOpenSwapEvent(
            newSwapId,
            newSwap,
            indicator,
            0,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount,
            spreadValue
        );

        return newSwapId;
    }

    function _openSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal nonReentrant returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            openTimestamp,
            totalAmount,
            maximumSlippage,
            collateralizationFactor
        );

        DataTypes.MiltonTotalBalanceMemory memory balance = _miltonStorage
            .getBalance();

        _validateLiqudityPoolUtylization(
            balance.liquidityPool,
            balance.receiveFixedSwaps,
            bosStruct.collateral,
            bosStruct.openingFee
        );

        uint256 spreadValue = _miltonSpreadModel.calculateSpreadRecFixed(
            _miltonStorage,
            openTimestamp,
            bosStruct.accruedIpor,
            bosStruct.collateral,
            bosStruct.openingFee
        );

        DataTypes.IporSwapIndicator
            memory indicator = _calculateDerivativeIndicators(
                openTimestamp,
                1,
                bosStruct.notional,
                spreadValue
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
                bosStruct.openingFee
            );

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        //TODO: sendValue z Address (use with ReentrancyGuard)
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), totalAmount);

        _emitOpenSwapEvent(
            newSwapId,
            newSwap,
            indicator,
            1,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount,
            spreadValue
        );

        return newSwapId;
    }

    function _validateLiqudityPoolUtylization(
        uint256 totalLiquidityPoolBalance,
        uint256 totalCollateralPerLegBalance,
        uint256 collateral,
        uint256 openingFee
    ) internal view {
        require(
            IMiltonLiquidityPoolUtilizationModel(
                _iporConfiguration.getMiltonLiquidityPoolUtilizationModel()
            ).calculateUtilizationRate(
                    totalLiquidityPoolBalance,
                    totalCollateralPerLegBalance,
                    collateral,
                    openingFee
                ) <=
                _iporAssetConfiguration
                    .getLiquidityPoolMaxUtilizationPercentage(),
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
        uint256 spreadValue
    ) internal {
        //TODO: add openingAmount to event and check in tests
        //TODO: add iporPublicationAmount to event and check in test
        //TODO: add spreadValue to event and check in test
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
            spreadValue
        );
    }

    function _calculateDerivativeIndicators(
        uint256 calculateTimestamp,
        uint8 direction,
        uint256 notionalAmount,
        uint256 spreadValue
    ) internal view returns (DataTypes.IporSwapIndicator memory indicator) {
        (
            uint256 iporIndexValue,
            ,
            uint256 exponentialMovingAverage,
            ,

        ) = _warren.getIndex(_asset);
        uint256 accruedIbtPrice = _warren.calculateAccruedIbtPrice(
            _asset,
            calculateTimestamp
        );
        require(
            accruedIbtPrice != 0,
            IporErrors.MILTON_IBT_PRICE_CANNOT_BE_ZERO
        );
        require(
            iporIndexValue >= spreadValue,
            IporErrors.MILTON_SPREAD_CANNOT_BE_HIGHER_THAN_IPOR_INDEX
        );

        indicator = DataTypes.IporSwapIndicator(
            iporIndexValue,
            accruedIbtPrice,
            IporMath.division(notionalAmount * Constants.D18, accruedIbtPrice),
            direction == 0
                ? (_calculateReferenceLegPayFixed(
                    iporIndexValue,
                    exponentialMovingAverage
                ) + spreadValue)
                : iporIndexValue > spreadValue
                ? (_calculateReferenceLegRecFixed(
                    iporIndexValue,
                    exponentialMovingAverage
                ) - spreadValue)
                : 0
        );
    }

    function _calculateReferenceLegPayFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue > exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }

    function _calculateReferenceLegRecFixed(
        uint256 iporIndexValue,
        uint256 exponentialMovingAverage
    ) internal pure returns (uint256) {
        if (iporIndexValue < exponentialMovingAverage) {
            return iporIndexValue;
        } else {
            return exponentialMovingAverage;
        }
    }

    function _closeSwapPayFixed(uint256 swapId, uint256 closeTimestamp)
        internal
    {
        require(
            swapId != 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_SWAP_ID
        );

        //TODO: clarify if needed whole item here??
        DataTypes.IporSwapMemory memory iporSwap = _miltonStorage
            .getSwapPayFixed(swapId);

        require(
            iporSwap.state == uint256(DataTypes.SwapState.ACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        uint256 incomeTaxPercentage = _iporAssetConfiguration
            .getIncomeTaxPercentage();

        int256 positionValue = _calculateSwapPayFixedValue(
            closeTimestamp,
            iporSwap
        );

        _miltonStorage.updateStorageWhenCloseSwapPayFixed(
            msg.sender,
            iporSwap,
            positionValue,
            closeTimestamp
        );

        _transferTokensBasedOnpositionValue(
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

        //TODO: clarify it whole item required?
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
            closeTimestamp
        );

        _transferTokensBasedOnpositionValue(
            iporSwap,
            positionValue,
            closeTimestamp,
            _iporAssetConfiguration.getIncomeTaxPercentage()
        );

        emit CloseSwap(swapId, _asset, closeTimestamp);
    }

    function _transferTokensBasedOnpositionValue(
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
            //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
            //transfer liquidation deposit amount from Milton to Sender
            IERC20(_asset).safeTransfer(
                msg.sender,
                IporMath.convertWadToAssetDecimals(
                    liquidationDepositAmount,
                    _decimals
                )
            );
        }

        if (transferAmount != 0) {
            //transfer from Milton to Trader
            //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
            IERC20(_asset).safeTransfer(
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
}
