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
import "./IMiltonEvents.sol";
import "../tokenization/IpToken.sol";

import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
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
    using DerivativeLogic for DataTypes.IporDerivativeMemory;

    uint8 private immutable _decimals;
    address private immutable _asset;
    IIporConfiguration internal _iporConfiguration;
    IIporAssetConfiguration internal _iporAssetConfiguration;
	

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

        _asset = asset;

        _iporAssetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );		

        _decimals = _iporAssetConfiguration.getDecimals();
    }

    modifier onlyActiveSwapPayFixed(uint256 derivativeId) {
        require(
            IMiltonStorage(_iporAssetConfiguration.getMiltonStorage())
                .getSwapPayFixedState(derivativeId) == 1,
            IporErrors.MILTON_DERIVATIVE_IS_INACTIVE
        );
        _;
    }

    modifier onlyActiveSwapReceiveFixed(uint256 derivativeId) {
        require(
            IMiltonStorage(_iporAssetConfiguration.getMiltonStorage())
                .getSwapReceiveFixedState(derivativeId) == 0,
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
        require(amount > 0, IporErrors.MILTON_NOT_ENOUGH_AMOUNT_TO_TRANSFER);

        //TODO: consider save this address inside Milton, use MiltonStorage as proxy, and manage this address directly on Milton
        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );
        require(
            amount <= miltonStorage.getBalance().openingFee,
            IporErrors.MILTON_NOT_ENOUGH_OPENING_FEE_BALANCE
        );
        address charlieTreasurer = _iporAssetConfiguration
            .getCharlieTreasurer();
        require(
            address(0) != charlieTreasurer,
            IporErrors.MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS
        );
        miltonStorage.updateStorageWhenTransferPublicationFee(amount);
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

    function calculateSwapPayFixedValue(
        DataTypes.IporDerivativeMemory memory derivative
    ) external view override returns (int256) {
        return _calculateSwapPayFixedValue(block.timestamp, derivative);
    }

    function calculateSwapReceiveFixedValue(
        DataTypes.IporDerivativeMemory memory derivative
    ) external view override returns (int256) {
        return _calculateSwapReceiveFixedValue(block.timestamp, derivative);
    }

    //TODO: refactor in this way that timestamp is not visible in external milton method
    function calculateExchangeRate(uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        IIpToken ipToken = IIpToken(_iporAssetConfiguration.getIpToken());
        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );
        (, , int256 soap) = _calculateSoap(calculateTimestamp);

        int256 balance = miltonStorage.getBalance().liquidityPool.toInt256() -
            soap;

        require(
            balance >= 0,
            IporErrors.JOSEPH_SOAP_AND_MILTON_LP_BALANCE_SUM_IS_TOO_LOW
        );
        uint256 ipTokenTotalSupply = ipToken.totalSupply();
        if (ipTokenTotalSupply > 0) {
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
        DataTypes.IporDerivativeMemory memory derivative
    ) internal view returns (int256) {
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterestForSwapPayFixed(
                timestamp,
                IWarren(_iporConfiguration.getWarren())
                    .calculateAccruedIbtPrice(_asset, timestamp)
            );
        //TODO: remove dublicates
        if (derivativeInterest.positionValue > 0) {
            if (
                derivativeInterest.positionValue <
                int256(uint256(derivative.collateral))
            ) {
                return derivativeInterest.positionValue;
            } else {
                return int256(uint256(derivative.collateral));
            }
        } else {
            if (
                derivativeInterest.positionValue <
                -int256(uint256(derivative.collateral))
            ) {
                return -int256(uint256(derivative.collateral));
            } else {
                return derivativeInterest.positionValue;
            }
        }
    }

    function _calculateSwapReceiveFixedValue(
        uint256 timestamp,
        DataTypes.IporDerivativeMemory memory derivative
    ) internal view returns (int256) {
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterestForSwapReceiveFixed(
                timestamp,
                IWarren(_iporConfiguration.getWarren())
                    .calculateAccruedIbtPrice(_asset, timestamp)
            );

        if (derivativeInterest.positionValue > 0) {
            if (
                derivativeInterest.positionValue <
                int256(uint256(derivative.collateral))
            ) {
                return derivativeInterest.positionValue;
            } else {
                return int256(uint256(derivative.collateral));
            }
        } else {
            if (
                derivativeInterest.positionValue <
                -int256(uint256(derivative.collateral))
            ) {
                return -int256(uint256(derivative.collateral));
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
        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            _iporConfiguration.getMiltonSpreadModel()
        );

        try
            spreadModel.calculatePartialSpreadPayFixed(
                calculateTimestamp,
                _asset
            )
        returns (uint256 _spreadPayFixedValue) {
            spreadPayFixedValue = _spreadPayFixedValue;
        } catch {
            spreadPayFixedValue = 0;
        }

        try
            spreadModel.calculatePartialSpreadRecFixed(
                calculateTimestamp,
                _asset
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
        IWarren warren = IWarren(_iporConfiguration.getWarren());
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(
            _asset,
            calculateTimestamp
        );
        (int256 _soapPf, int256 _soapRf, int256 _soap) = IMiltonStorage(_iporAssetConfiguration.getMiltonStorage()).calculateSoap(accruedIbtPrice, calculateTimestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _beforeOpenSwap(
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal view returns (DataTypes.BeforeOpenSwapStruct memory bosStruct) {
        require(
            maximumSlippage > 0,
            IporErrors.MILTON_MAXIMUM_SLIPPAGE_TOO_LOW
        );
        require(totalAmount > 0, IporErrors.MILTON_TOTAL_AMOUNT_TOO_LOW);

        require(
            IERC20(_asset).balanceOf(msg.sender) >= totalAmount,
            IporErrors.MILTON_ASSET_BALANCE_OF_TOO_LOW
        );

        uint256 wadTotalAmount = IporMath.convertToWad(totalAmount, _decimals);

        require(
            collateralizationFactor >=
                _iporAssetConfiguration.getMinCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_LOW
        );
        require(
            collateralizationFactor <=
                _iporAssetConfiguration.getMaxCollateralizationFactorValue(),
            IporErrors.MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH
        );

        require(
            wadTotalAmount >
                _iporAssetConfiguration.getLiquidationDepositAmount() +
                    _iporAssetConfiguration.getIporPublicationFeeAmount(),
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );
        require(
            wadTotalAmount <=
                _iporAssetConfiguration.getMaxPositionTotalAmount(),
            IporErrors.MILTON_TOTAL_AMOUNT_TOO_HIGH
        );

        require(
            maximumSlippage <=
                _iporAssetConfiguration.getMaxSlippagePercentage(),
            IporErrors.MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH
        );

        // require(
        //     direction <=
        //         uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed),
        //     IporErrors.MILTON_DERIVATIVE_DIRECTION_NOT_EXISTS
        // );

        (uint256 collateral, uint256 notional, uint256 openingFee) = IporMath
            .calculateDerivativeAmount(
                wadTotalAmount,
                collateralizationFactor,
                _iporAssetConfiguration.getLiquidationDepositAmount(),
                _iporAssetConfiguration.getIporPublicationFeeAmount(),
                _iporAssetConfiguration.getOpeningFeePercentage()
            );

        require(
            wadTotalAmount >
                _iporAssetConfiguration.getLiquidationDepositAmount() +
                    _iporAssetConfiguration.getIporPublicationFeeAmount() +
                    openingFee,
            IporErrors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        require(
            IMiltonLPUtilizationStrategy(
                _iporConfiguration.getMiltonLPUtilizationStrategy()
            ).calculateTotalUtilizationRate(_asset, collateral, openingFee) <=
                _iporAssetConfiguration
                    .getLiquidityPoolMaxUtilizationPercentage(),
            IporErrors.MILTON_LIQUIDITY_POOL_UTILISATION_EXCEEDED
        );

        return
            DataTypes.BeforeOpenSwapStruct(
                wadTotalAmount,
                collateral,
                notional,
                openingFee,
                _iporAssetConfiguration.getLiquidationDepositAmount(),
                _decimals,
                _iporAssetConfiguration.getIporPublicationFeeAmount()
            );
    }

    function _openSwapPayFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal nonReentrant returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            totalAmount,
            maximumSlippage,
            collateralizationFactor
        );

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            _iporConfiguration.getMiltonSpreadModel()
        );

        uint256 spreadValue = spreadModel.calculateSpreadPayFixed(
            openTimestamp,
            _asset,
            bosStruct.collateral,
            bosStruct.openingFee
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );

        DataTypes.IporDerivativeIndicator
            memory indicator = _calculateDerivativeIndicators(
                openTimestamp,
                0,
                bosStruct.notional,
                spreadValue
            );

        DataTypes.IporDerivativeMemory memory iporDerivative = DataTypes
            .IporDerivativeMemory(
                uint256(DataTypes.DerivativeState.ACTIVE),
                msg.sender,
                openTimestamp,
                openTimestamp + Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
                miltonStorage.getLastSwapId() + 1,
                bosStruct.collateral,
                bosStruct.liquidationDepositAmount,
                bosStruct.notional,
                indicator.fixedInterestRate,
                indicator.ibtQuantity
            );

			miltonStorage.updateStorageWhenOpenSwapPayFixed(
            iporDerivative,
            bosStruct.openingFee
        );

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        //TODO: sendValue z Address (use with ReentrancyGuard)
        IERC20(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            IporMath.convertWadToAssetDecimals(
                bosStruct.wadTotalAmount,
                bosStruct.decimals
            )
        );

        _emitOpenPositionEvent(
            iporDerivative,
            indicator,
            0,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount,
            spreadValue
        );

        return iporDerivative.id;
    }

    function _openSwapReceiveFixed(
        uint256 openTimestamp,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor
    ) internal nonReentrant returns (uint256) {
        DataTypes.BeforeOpenSwapStruct memory bosStruct = _beforeOpenSwap(
            totalAmount,
            maximumSlippage,
            collateralizationFactor
        );

        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            _iporConfiguration.getMiltonSpreadModel()
        );

        uint256 spreadValue = spreadModel.calculateSpreadRecFixed(
            openTimestamp,
            _asset,
            bosStruct.collateral,
            bosStruct.openingFee
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );

        DataTypes.IporDerivativeIndicator
            memory indicator = _calculateDerivativeIndicators(
                openTimestamp,
                1,
                bosStruct.notional,
                spreadValue
            );

        DataTypes.IporDerivativeMemory memory iporDerivative = DataTypes
            .IporDerivativeMemory(
                uint256(DataTypes.DerivativeState.ACTIVE),
                msg.sender,
                openTimestamp,
                openTimestamp + Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
                //TODO: move this operation inside MiltonStorage
                miltonStorage.getLastSwapId() + 1,
                bosStruct.collateral,
                bosStruct.liquidationDepositAmount,
                bosStruct.notional,
                indicator.fixedInterestRate,
                indicator.ibtQuantity
            );

			miltonStorage.updateStorageWhenOpenSwapReceiveFixed(
            iporDerivative,
            bosStruct.openingFee
        );

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        //TODO: sendValue z Address (use with ReentrancyGuard)
        IERC20(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            IporMath.convertWadToAssetDecimals(totalAmount, bosStruct.decimals)
        );

        _emitOpenPositionEvent(
            iporDerivative,
            indicator,
            1,
            bosStruct.openingFee,
            bosStruct.iporPublicationFeeAmount,
            spreadValue
        );

        return iporDerivative.id;
    }

    function _emitOpenPositionEvent(
        DataTypes.IporDerivativeMemory memory iporDerivative,
        DataTypes.IporDerivativeIndicator memory indicator,
        uint256 direction,
        uint256 openingAmount,
        uint256 iporPublicationAmount,
        uint256 spreadValue
    ) internal {
        //TODO: add openingAmount to event and check in tests
        //TODO: add iporPublicationAmount to event and check in test
        //TODO: add spreadValue to event and check in test
        emit OpenPosition(
            iporDerivative.id,
            iporDerivative.buyer,
            _asset,
            DataTypes.DerivativeDirection(direction),
            iporDerivative.collateral,
            iporDerivative.liquidationDepositAmount,
            iporDerivative.notionalAmount,
            iporDerivative.startingTimestamp,
            iporDerivative.endingTimestamp,
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
    )
        internal
        view
        returns (DataTypes.IporDerivativeIndicator memory indicator)
    {
        IWarren warren = IWarren(_iporConfiguration.getWarren());
        (
            uint256 iporIndexValue,
            ,
            uint256 exponentialMovingAverage,
            ,

        ) = warren.getIndex(_asset);
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(
            _asset,
            calculateTimestamp
        );
        require(
            accruedIbtPrice > 0,
            IporErrors.MILTON_IBT_PRICE_CANNOT_BE_ZERO
        );
        require(
            iporIndexValue >= spreadValue,
            IporErrors.MILTON_SPREAD_CANNOT_BE_HIGHER_THAN_IPOR_INDEX
        );

        indicator = DataTypes.IporDerivativeIndicator(
            iporIndexValue,
            accruedIbtPrice,
            IporMath.calculateIbtQuantity(notionalAmount, accruedIbtPrice),
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

    function _closeSwapPayFixed(uint256 derivativeId, uint256 closeTimestamp)
        internal
    {
        require(
            derivativeId > 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );

        //TODO: clarify if needed whole item here??
        DataTypes.MiltonDerivativeItemMemory
            memory derivativeItem = miltonStorage.getSwapPayFixedItem(
                derivativeId
            );

        require(
            derivativeItem.item.state ==
                uint256(DataTypes.DerivativeState.ACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        uint256 incomeTaxPercentage = _iporAssetConfiguration
            .getIncomeTaxPercentage();

        int256 positionValue = _calculateSwapPayFixedValue(
            closeTimestamp,
            derivativeItem.item
        );

        miltonStorage.updateStorageWhenCloseSwapPayFixed(
            msg.sender,
            derivativeItem,
            positionValue,
            closeTimestamp
        );

        _transferTokensBasedOnpositionValue(
            derivativeItem,
            positionValue,
            closeTimestamp,
            incomeTaxPercentage
        );

        emit ClosePosition(derivativeId, _asset, closeTimestamp);
    }

    function _closeSwapReceiveFixed(
        uint256 derivativeId,
        uint256 closeTimestamp
    ) internal {
        require(
            derivativeId > 0,
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporAssetConfiguration.getMiltonStorage()
        );

        //TODO: clarify it whole item required?
        DataTypes.MiltonDerivativeItemMemory
            memory derivativeItem = miltonStorage.getSwapReceiveFixedItem(
                derivativeId
            );

        require(
            derivativeItem.item.state ==
                uint256(DataTypes.DerivativeState.ACTIVE),
            IporErrors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        int256 positionValue = _calculateSwapReceiveFixedValue(
            closeTimestamp,
            derivativeItem.item
        );

        miltonStorage.updateStorageWhenCloseSwapReceiveFixed(
            msg.sender,
            derivativeItem,
            positionValue,
            closeTimestamp
        );

        _transferTokensBasedOnpositionValue(
            derivativeItem,
            positionValue,
            closeTimestamp,
            _iporAssetConfiguration.getIncomeTaxPercentage()
        );

        emit ClosePosition(derivativeId, _asset, closeTimestamp);
    }

    function _transferTokensBasedOnpositionValue(
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
        int256 positionValue,
        uint256 _calculationTimestamp,
        uint256 incomeTaxPercentage
    ) internal {
        uint256 abspositionValue = IporMath.absoluteValue(positionValue);

        if (abspositionValue < derivativeItem.item.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (msg.sender != derivativeItem.item.buyer) {
                require(
                    _calculationTimestamp >=
                        derivativeItem.item.endingTimestamp,
                    IporErrors
                        .MILTON_CANNOT_CLOSE_DERIVATE_SENDER_IS_NOT_BUYER_AND_NO_DERIVATIVE_MATURITY
                );
            }
        }

        if (positionValue > 0) {
            //Trader earn, Milton loose
            _transferDerivativeAmount(
                derivativeItem,
                derivativeItem.item.collateral +
                    abspositionValue -
                    IporMath.calculateIncomeTax(
                        abspositionValue,
                        incomeTaxPercentage
                    )
            );
        } else {
            //Milton earn, Trader looseMiltonStorage
            _transferDerivativeAmount(
                derivativeItem,
                derivativeItem.item.collateral - abspositionValue
            );
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(
        DataTypes.MiltonDerivativeItemMemory memory derivativeItem,
        uint256 transferAmount
    ) internal {
        if (msg.sender == derivativeItem.item.buyer) {
            transferAmount =
                transferAmount +
                derivativeItem.item.liquidationDepositAmount;
        } else {
            //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
            //transfer liquidation deposit amount from Milton to Sender
            IERC20(_asset).safeTransfer(
                msg.sender,
                IporMath.convertWadToAssetDecimals(
                    derivativeItem.item.liquidationDepositAmount,
                    _decimals
                )
            );
        }

        if (transferAmount > 0) {
            //transfer from Milton to Trader
            //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
            IERC20(_asset).safeTransfer(
                derivativeItem.item.buyer,
                IporMath.convertWadToAssetDecimals(transferAmount, _decimals)
            );
        }
    }
}
