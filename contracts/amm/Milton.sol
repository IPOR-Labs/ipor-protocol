// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../libraries/AmmMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Errors} from "../Errors.sol";
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
    using SafeCast for int256;

    using DerivativeLogic for DataTypes.IporDerivative;

    IIporConfiguration internal _iporConfiguration;

    modifier onlyActiveDerivative(uint256 derivativeId) {
        require(
            IMiltonStorage(_iporConfiguration.getMiltonStorage())
                .getDerivativeItem(derivativeId)
                .item
                .state == DataTypes.DerivativeState.ACTIVE,
            Errors.MILTON_DERIVATIVE_IS_INACTIVE
        );
        _;
    }

    modifier onlyPublicationFeeTransferer() {
        require(
            msg.sender == _iporConfiguration.getMiltonPublicationFeeTransferer(),
            Errors.MILTON_CALLER_NOT_MILTON_PUBLICATION_FEE_TRANSFERER
        );
        _;
    }

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration)
        external
        onlyOwner
    {
        _iporConfiguration = initialIporConfiguration;
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

    function authorizeJoseph(address asset)
        external
        override
        onlyOwner
        whenNotPaused
    {
        IERC20(asset).safeIncreaseAllowance(
            _iporConfiguration.getJoseph(),
            Constants.MAX_VALUE
        );
    }

    //@notice transfer publication fee to configured charlie treasurer address
    function transferPublicationFee(address asset, uint256 amount)
        external
        onlyPublicationFeeTransferer
    {
        require(amount > 0, Errors.MILTON_NOT_ENOUGH_AMOUNT_TO_TRANSFER);
        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporConfiguration.getMiltonStorage()
        );
        require(
            amount <= miltonStorage.getBalance(asset).openingFee,
            Errors.MILTON_NOT_ENOUGH_OPENING_FEE_BALANCE
        );
        address charlieTreasurer = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        ).getCharlieTreasurer();
        require(
            address(0) != charlieTreasurer,
            Errors.MILTON_INCORRECT_CHARLIE_TREASURER_ADDRESS
        );
        miltonStorage.updateStorageWhenTransferPublicationFee(asset, amount);
        //TODO: user Address from OZ and use call
        //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
        IERC20(asset).safeTransfer(charlieTreasurer, amount);
    }

    //TODO: !!! consider connect configuration with milton storage,
    //in this way that if there is parameter used only in open and close position then let put it in miltonstorage
    function openPosition(
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor,
        uint8 direction
    ) external override returns (uint256) {
        return
            _openPosition(
                block.timestamp,
                asset,
                totalAmount,
                maximumSlippage,
                collateralizationFactor,
                direction
            );
    }

    function closePosition(uint256 derivativeId)
        external
        override
        onlyActiveDerivative(derivativeId)
        nonReentrant
    {
        _closePosition(derivativeId, block.timestamp);
    }

    function calculateSpread(address asset)
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        (spreadPayFixedValue, spreadRecFixedValue) = _calculateSpread(
            asset,
            block.timestamp
        );
    }

    function calculateSoap(address asset)
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
            asset,
            block.timestamp
        );
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function calculatePositionValue(DataTypes.IporDerivative memory derivative)
        external
        view
        override
        returns (int256)
    {
        return _calculatePositionValue(block.timestamp, derivative);
    }

    //TODO: refactor in this way that timestamp is not visible in external milton method
    function calculateExchangeRate(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256)
    {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        IIpToken ipToken = IIpToken(iporAssetConfiguration.getIpToken());
        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporConfiguration.getMiltonStorage()
        );
        (, , int256 soap) = _calculateSoap(asset, calculateTimestamp);
        int256 balance = miltonStorage
            .getBalance(asset)
            .liquidityPool
            .toInt256() + soap;
        require(
            balance >= 0,
            Errors.JOSEPH_SOAP_AND_MILTON_LP_BALANCE_SUM_IS_TOO_LOW
        );
        uint256 ipTokenTotalSupply = ipToken.totalSupply();
        if (ipTokenTotalSupply > 0) {
            return
                AmmMath.division(
                    balance.toUint256() * Constants.D18,
                    ipTokenTotalSupply
                );
        } else {
            return Constants.D18;
        }
    }

    function _calculatePositionValue(
        uint256 timestamp,
        DataTypes.IporDerivative memory derivative
    ) internal view returns (int256) {
        DataTypes.IporDerivativeInterest memory derivativeInterest = derivative
            .calculateInterest(
                timestamp,
                IWarren(_iporConfiguration.getWarren()).calculateAccruedIbtPrice(
                    derivative.asset,
                    timestamp
                )
            );

        if (derivativeInterest.positionValue > 0) {
            if (
                derivativeInterest.positionValue < int256(derivative.collateral)
            ) {
                return derivativeInterest.positionValue;
            } else {
                return int256(derivative.collateral);
            }
        } else {
            if (
                derivativeInterest.positionValue <
                -int256(derivative.collateral)
            ) {
                return -int256(derivative.collateral);
            } else {
                return derivativeInterest.positionValue;
            }
        }
    }

    function _calculateSpread(address asset, uint256 calculateTimestamp)
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
                asset
            )
        returns (uint256 _spreadPayFixedValue) {
            spreadPayFixedValue = _spreadPayFixedValue;
        } catch {
            spreadPayFixedValue = 0;
        }

        try
            spreadModel.calculatePartialSpreadRecFixed(
                calculateTimestamp,
                asset
            )
        returns (uint256 _spreadRecFixedValue) {
            spreadRecFixedValue = _spreadRecFixedValue;
        } catch {
            spreadRecFixedValue = 0;
        }
    }

    function _calculateSoap(address asset, uint256 calculateTimestamp)
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
            asset,
            calculateTimestamp
        );
        (int256 _soapPf, int256 _soapRf, int256 _soap) = IMiltonStorage(
            _iporConfiguration.getMiltonStorage()
        ).calculateSoap(asset, accruedIbtPrice, calculateTimestamp);
        return (soapPf = _soapPf, soapRf = _soapRf, soap = _soap);
    }

    function _openPosition(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor,
        uint8 direction
    ) internal nonReentrant returns (uint256) {
        //TODO: consider remove this requirements
        require(
            address(_iporConfiguration) != address(0),
            Errors.MILTON_INCORRECT_ADRESSES_MANAGER_ADDRESS
        );
        //TODO: consider remove this requirements
        require(asset != address(0), Errors.MILTON_LIQUIDITY_POOL_NOT_EXISTS);
        require(maximumSlippage > 0, Errors.MILTON_MAXIMUM_SLIPPAGE_TOO_LOW);
        require(totalAmount > 0, Errors.MILTON_TOTAL_AMOUNT_TOO_LOW);
        require(
            _iporConfiguration.assetSupported(asset) == 1,
            Errors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        require(
            address(iporAssetConfiguration) != address(0),
            Errors.MILTON_INCORRECT_CONFIGURATION_ADDRESS
        );

        require(
            IERC20(asset).balanceOf(msg.sender) >= totalAmount,
            Errors.MILTON_ASSET_BALANCE_OF_TOO_LOW
        );

        //TODO: ask front to send always in 18 decimals	for collateralizationFactor and maxumumSlippage, totalAmount leave in decimals specific for asset
        totalAmount = AmmMath.convertToWad(
            totalAmount,
            iporAssetConfiguration.getDecimals()
        );
        collateralizationFactor = AmmMath.convertToWad(
            collateralizationFactor,
            iporAssetConfiguration.getDecimals()
        );
        maximumSlippage = AmmMath.convertToWad(
            maximumSlippage,
            iporAssetConfiguration.getDecimals()
        );

        require(
            collateralizationFactor >=
                iporAssetConfiguration.getMinCollateralizationFactorValue(),
            Errors.MILTON_COLLATERALIZATION_FACTOR_TOO_LOW
        );
        require(
            collateralizationFactor <=
                iporAssetConfiguration.getMaxCollateralizationFactorValue(),
            Errors.MILTON_COLLATERALIZATION_FACTOR_TOO_HIGH
        );

        require(
            totalAmount >
                iporAssetConfiguration.getLiquidationDepositAmount() +
                    iporAssetConfiguration.getIporPublicationFeeAmount(),
            Errors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );
        require(
            totalAmount <= iporAssetConfiguration.getMaxPositionTotalAmount(),
            Errors.MILTON_TOTAL_AMOUNT_TOO_HIGH
        );

        require(
            maximumSlippage <=
                iporAssetConfiguration.getMaxSlippagePercentage(),
            Errors.MILTON_MAXIMUM_SLIPPAGE_TOO_HIGH
        );

        require(
            direction <=
                uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed),
            Errors.MILTON_DERIVATIVE_DIRECTION_NOT_EXISTS
        );

        DataTypes.IporDerivativeAmount memory derivativeAmount = AmmMath
            .calculateDerivativeAmount(
                totalAmount,
                collateralizationFactor,
                iporAssetConfiguration.getLiquidationDepositAmount(),
                iporAssetConfiguration.getIporPublicationFeeAmount(),
                iporAssetConfiguration.getOpeningFeePercentage()
            );

        require(
            totalAmount >
                iporAssetConfiguration.getLiquidationDepositAmount() +
                    iporAssetConfiguration.getIporPublicationFeeAmount() +
                    derivativeAmount.openingFee,
            Errors.MILTON_TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        require(
            IMiltonLPUtilizationStrategy(
                _iporConfiguration.getMiltonLPUtilizationStrategy()
            ).calculateTotalUtilizationRate(
                    asset,
                    derivativeAmount.deposit,
                    derivativeAmount.openingFee
                ) <=
                iporAssetConfiguration
                    .getLiquidityPoolMaxUtilizationPercentage(),
            Errors.MILTON_LIQUIDITY_POOL_UTILISATION_EXCEEDED
        );

        uint256 spreadValue;
        IMiltonSpreadModel spreadModel = IMiltonSpreadModel(
            _iporConfiguration.getMiltonSpreadModel()
        );

        if (direction == 0) {
            spreadValue = spreadModel.calculateSpreadPayFixed(
                openTimestamp,
                asset,
                derivativeAmount.deposit,
                derivativeAmount.openingFee
            );
        } else {
            spreadValue = spreadModel.calculateSpreadRecFixed(
                openTimestamp,
                asset,
                derivativeAmount.deposit,
                derivativeAmount.openingFee
            );
        }

        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporConfiguration.getMiltonStorage()
        );

        DataTypes.IporDerivative memory iporDerivative = DataTypes
            .IporDerivative(
                miltonStorage.getLastDerivativeId() + 1,
                DataTypes.DerivativeState.ACTIVE,
                msg.sender,
                asset,
                direction,
                derivativeAmount.deposit,
                DataTypes.IporDerivativeFee(
                    iporAssetConfiguration.getLiquidationDepositAmount(),
                    derivativeAmount.openingFee,
                    iporAssetConfiguration.getIporPublicationFeeAmount(),
                    spreadValue
                ),
                collateralizationFactor,
                derivativeAmount.notional,
                openTimestamp,
                openTimestamp + Constants.DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
                _calculateDerivativeIndicators(
                    openTimestamp,
                    asset,
                    direction,
                    derivativeAmount.notional,
                    spreadValue
                )
            );

        miltonStorage.updateStorageWhenOpenPosition(iporDerivative);

        //TODO:Use call() instead, without hardcoded gas limits along with checks-effects-interactions pattern or reentrancy guards for reentrancy protection.
        //TODO: https://swcregistry.io/docs/SWC-134, https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        //TODO: change transfer to call - transfer rely on gas cost :EDIT May 2021: call{value: amount}("") should now be used for transferring ether (Do not use send or transfer.)
        //TODO: https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642
        //TODO: sendValue z Address (use with ReentrancyGuard)
        IERC20(asset).safeTransferFrom(
            msg.sender,
            address(this),
            AmmMath.convertWadToAssetDecimals(
                totalAmount,
                iporAssetConfiguration.getDecimals()
            )
        );

        _emitOpenPositionEvent(iporDerivative);

        return iporDerivative.id;
    }

    function _emitOpenPositionEvent(
        DataTypes.IporDerivative memory iporDerivative
    ) internal {
        emit OpenPosition(
            iporDerivative.id,
            iporDerivative.buyer,
            iporDerivative.asset,
            DataTypes.DerivativeDirection(iporDerivative.direction),
            iporDerivative.collateral,
            iporDerivative.fee,
            iporDerivative.collateralizationFactor,
            iporDerivative.notionalAmount,
            iporDerivative.startingTimestamp,
            iporDerivative.endingTimestamp,
            iporDerivative.indicator
        );
    }

    function _calculateDerivativeIndicators(
        uint256 calculateTimestamp,
        address asset,
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

        ) = warren.getIndex(asset);
        uint256 accruedIbtPrice = warren.calculateAccruedIbtPrice(
            asset,
            calculateTimestamp
        );
        require(accruedIbtPrice > 0, Errors.MILTON_IBT_PRICE_CANNOT_BE_ZERO);
        require(
            iporIndexValue >= spreadValue,
            Errors.MILTON_SPREAD_CANNOT_BE_HIGHER_THAN_IPOR_INDEX
        );

        indicator = DataTypes.IporDerivativeIndicator(
            iporIndexValue,
            accruedIbtPrice,
            AmmMath.calculateIbtQuantity(notionalAmount, accruedIbtPrice),
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

    function _closePosition(uint256 derivativeId, uint256 closeTimestamp)
        internal
    {
        require(
            derivativeId > 0,
            Errors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_ID
        );

        IMiltonStorage miltonStorage = IMiltonStorage(
            _iporConfiguration.getMiltonStorage()
        );

        DataTypes.MiltonDerivativeItem memory derivativeItem = miltonStorage
            .getDerivativeItem(derivativeId);

        require(
            derivativeItem.item.state == DataTypes.DerivativeState.ACTIVE,
            Errors.MILTON_CLOSE_POSITION_INCORRECT_DERIVATIVE_STATUS
        );

        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(
                    derivativeItem.item.asset
                )
            );

        uint256 incomeTaxPercentage = iporAssetConfiguration
            .getIncomeTaxPercentage();

        int256 positionValue = _calculatePositionValue(
            closeTimestamp,
            derivativeItem.item
        );

        miltonStorage.updateStorageWhenClosePosition(
            msg.sender,
            derivativeItem,
            positionValue,
            closeTimestamp
        );

        _transferTokensBasedOnpositionValue(
            derivativeItem,
            positionValue,
            closeTimestamp,
            incomeTaxPercentage,
            iporAssetConfiguration.getDecimals()
        );

        emit ClosePosition(
            derivativeId,
            derivativeItem.item.asset,
            closeTimestamp
        );
    }

    function _transferTokensBasedOnpositionValue(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        int256 positionValue,
        uint256 _calculationTimestamp,
        uint256 incomeTaxPercentage,
        uint256 assetDecimals
    ) internal {
        uint256 abspositionValue = AmmMath.absoluteValue(positionValue);

        if (abspositionValue < derivativeItem.item.collateral) {
            //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
            if (msg.sender != derivativeItem.item.buyer) {
                require(
                    _calculationTimestamp >=
                        derivativeItem.item.endingTimestamp,
                    Errors
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
                    AmmMath.calculateIncomeTax(
                        abspositionValue,
                        incomeTaxPercentage
                    ),
                assetDecimals
            );
        } else {
            //Milton earn, Trader looseMiltonStorage
            _transferDerivativeAmount(
                derivativeItem,
                derivativeItem.item.collateral - abspositionValue,
                assetDecimals
            );
        }
    }

    //Depends on condition transfer only to sender (when sender == buyer) or to sender and buyer
    function _transferDerivativeAmount(
        DataTypes.MiltonDerivativeItem memory derivativeItem,
        uint256 transferAmount,
        uint256 assetDecimals
    ) internal {
        if (msg.sender == derivativeItem.item.buyer) {
            transferAmount =
                transferAmount +
                derivativeItem.item.fee.liquidationDepositAmount;
        } else {
            //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
            //transfer liquidation deposit amount from Milton to Sender
            IERC20(derivativeItem.item.asset).safeTransfer(
                msg.sender,
                AmmMath.convertWadToAssetDecimals(
                    derivativeItem.item.fee.liquidationDepositAmount,
                    assetDecimals
                )
            );
        }

        if (transferAmount > 0) {
            //transfer from Milton to Trader
            //TODO: C33 - Don't use address.transfer() or address.send(). Use .call.value(...)("") instead. (SWC-134)
            IERC20(derivativeItem.item.asset).safeTransfer(
                derivativeItem.item.buyer,
                AmmMath.convertWadToAssetDecimals(transferAmount, assetDecimals)
            );
        }
    }
}
