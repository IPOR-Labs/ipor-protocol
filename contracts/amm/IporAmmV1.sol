// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Errors} from '../Errors.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import "../interfaces/IIporOracle.sol";
import './IporAmmStorage.sol';
import './IporAmmEvents.sol';
import './IporPool.sol';
import "../libraries/types/DataTypes.sol";

/**
 * @title Automated Market Maker for derivatives based on IPOR Index.
 *
 * @author IPOR Labs
 */
contract IporAmmV1 is IporAmmV1Storage, IporAmmV1Events {

    IIporOracle public iporOracle;

    //@notice Year in seconds
    uint256 constant YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

    //@notice By default every derivative takes 28 days, this variable show this value in seconds
    uint256 constant DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = 60 * 60 * 24 * 28;

    uint256 constant YEAR_PER_DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS = DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS / YEAR_IN_SECONDS;

    //@notice amount of asset taken in case of deposit liquidation
    uint256 constant LIQUIDATION_DEPOSIT_FEE_AMOUNT = 20 * 1e18;

    //@notice percentage of deposit amount
    uint256 constant OPENING_FEE_PERCENTAGE = 1e16;

    //@notice amount of asset taken for IPOR publication
    uint256 constant IPOR_PUBLICATION_FEE_AMOUNT = 10 * 1e18;

    //@notice percentage of deposit amount
    uint256 constant SPREAD_FEE_PERCENTAGE = 1e16;


    constructor(address _iporOracle, address _usdtToken, address _usdcToken, address _daiToken) {

        admin = msg.sender;

        iporOracle = IIporOracle(_iporOracle);

        tokens["USDT"] = _usdtToken;
        tokens["USDC"] = _usdcToken;
        tokens["DAI"] = _daiToken;

        //TODO: allow admin to setup it during runtime
        closingFeePercentage = 0;

    }

    /**
    * @notice Trader open new derivative position. Depending on the direction it could be derivative
    * where trader pay fixed and receive a floating (long position) or receive fixed and pay a floating.
    * @param _asset symbol of asset of the derivative
    * @param _totalAmount sum of deposit amount and fees
    * @param _leverage leverage level - proportion between _depositAmount and notional amount
    * @param _direction pay fixed and receive a floating (trader assume that interest rate will increase)
    * or receive a floating and pay fixed (trader assume that interest rate will decrease)
    * In a long position the trader will pay a fixed rate and receive a floating rate.
    */
    function openPosition(
        string memory _asset,
        uint256 _totalAmount,
        uint256 _maximumSlippage,
        uint8 _leverage,
        uint8 _direction) public {

        require(_leverage > 0, Errors.AMM_LEVERAGE_TOO_LOW);
        require(_totalAmount > 0, Errors.AMM_TOTAL_AMOUNT_TOO_LOW);
        require(_totalAmount > LIQUIDATION_DEPOSIT_FEE_AMOUNT + IPOR_PUBLICATION_FEE_AMOUNT, Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);
        require(_totalAmount <= 1e24, Errors.AMM_TOTAL_AMOUNT_TOO_HIGH);
        require(_maximumSlippage > 0, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_LOW);
        require(_maximumSlippage <= 1e20, Errors.AMM_MAXIMUM_SLIPPAGE_TOO_HIGH);
        require(tokens[_asset] != address(0), Errors.AMM_LIQUIDITY_POOL_NOT_EXISTS);
        require(_direction <= uint8(DataTypes.DerivativeDirection.PayFloatingReceiveFixed), Errors.AMM_DERIVATIVE_DIRECTION_NOT_EXISTS);
        require(IERC20(tokens[_asset]).balanceOf(msg.sender) >= _totalAmount, Errors.AMM_ASSET_BALANCE_OF_TOO_LOW);
        //TODO consider check if it is smart contract, if yes then revert
        //TODO verify if this opened derivatives is closable based on liquidity pool
        //TODO: add configurable parameter which describe utilization rate of liquidity pool (total deposit amount / total liquidity)
        //TODO: verify
        DataTypes.IporDerivativeAmount memory derivativeAmount = _calculateDerivativeAmount(_totalAmount, _leverage);
        require(_totalAmount > LIQUIDATION_DEPOSIT_FEE_AMOUNT + IPOR_PUBLICATION_FEE_AMOUNT + derivativeAmount.openingFee, Errors.AMM_TOTAL_AMOUNT_LOWER_THAN_FEE);

        (uint256 iporIndexValue, uint256  ibtPrice,) = iporOracle.getIndex(_asset);

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            iporIndexValue,
            ibtPrice,
            _calculateIbtQuantity(_asset, derivativeAmount.notional),
            _direction == 0 ? (iporIndexValue + SPREAD_FEE_PERCENTAGE) : (iporIndexValue - SPREAD_FEE_PERCENTAGE),
            soap
        );

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            LIQUIDATION_DEPOSIT_FEE_AMOUNT,
            derivativeAmount.openingFee,
            IPOR_PUBLICATION_FEE_AMOUNT,
            SPREAD_FEE_PERCENTAGE);

        uint256 startingTimestamp = block.timestamp;

        derivatives.push(
            DataTypes.IporDerivative(
                nextDerivativeId,
                DataTypes.DerivativeState.ACTIVE,
                msg.sender,
                _asset,
                _direction,
                derivativeAmount.deposit,
                fee,
                _leverage,
                derivativeAmount.notional,
                startingTimestamp,
                startingTimestamp + DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
                indicator
            )
        );

        nextDerivativeId++;

        IERC20(tokens[_asset]).transferFrom(msg.sender, address(this), _totalAmount);

        derivativesTotalBalances[_asset] = derivativesTotalBalances[_asset] + derivativeAmount.deposit;
        openingFeeTotalBalances[_asset] = openingFeeTotalBalances[_asset] + derivativeAmount.openingFee;
        liquidationDepositFeeTotalBalances[_asset] = liquidationDepositFeeTotalBalances[_asset] + LIQUIDATION_DEPOSIT_FEE_AMOUNT;
        iporPublicationFeeTotalBalances[_asset] = iporPublicationFeeTotalBalances[_asset] + IPOR_PUBLICATION_FEE_AMOUNT;
        liquidityPoolTotalBalances[_asset] = liquidityPoolTotalBalances[_asset] + derivativeAmount.openingFee;

        emit OpenPosition(
            nextDerivativeId,
            msg.sender,
            _asset,
            DataTypes.DerivativeDirection(_direction),
            derivativeAmount.deposit,
            fee,
            _leverage,
            derivativeAmount.notional,
            startingTimestamp,
            startingTimestamp + DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS,
            indicator
        );

        //TODO: clarify if ipAsset should be transfered to trader when position is opened
    }

    function closePosition(uint256 _derivativeId) onlyActiveDerivative(_derivativeId) public {

        //TODO: verify if sender can close derivative
        //TODO: owner moze zamknąc zawsze, ktokolwiek moze zamknąc gdy: minęło 28 dni (maturity), gdy jest poza zakresem +- 100%
        //TODO: liquidation deposit trafia do osoby która wykona zamknięcie depozytu
        //TODO: potwierdzić czy likwidacji może dokonywać inny smartcontract czy tylko 'osoba'
        //        require(derivatives[_derivativeId].startingTimestamp >= block.timestamp + DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS, "maturity not achieved");

        derivatives[_derivativeId].state = DataTypes.DerivativeState.INACTIVE;

        DataTypes.IporDerivativeInterest memory derivativeInterest = _calculateDerivativeInterest(_derivativeId);

        //P = D + I
        int256 I = 0;
        //
        //        //pay fixed, receive floating
        //        if (derivatives[_derivativeId].direction == 0) {
        //            I = iFloating - iFixed;
        //            //calculate P = D + I;
        //            if (I > 0) {
        //
        //                if (I > derivatives[_derivativeId].depositAmount){
        //                    //fetch D amount from Liquidity Pool
        //                    //transfer D+D to user's address
        //                } else {
        //                    //fetch I amount from Liquidity Pool
        //                    //transfer P=D+I to user's address
        //                }
        //
        //            } else {
        //                //transfer P to user's address
        //                //transfer |I| to liquidity pool
        //
        //                if (I > derivatives[_derivativeId].depositAmount){
        //                    //transfer D  to Liquidity Pool
        //                } else {
        //                    //transfer I to Liquidity Pool
        //                    //transfer D-I to user's address
        //                }
        //            }
        //        }
        //
        //        //receive fixed, pay floating
        //        if (derivatives[_derivativeId].direction == 1) {
        //            I = iFixed - iFloating;
        //            if (I > 0) {
        //                if (I > derivatives[_derivativeId].depositAmount){
        //                } else {
        //
        //                }
        //            } else {
        //                if (I > derivatives[_derivativeId].depositAmount){
        //                } else {
        //
        //                }
        //            }
        //        }

        //TODO: check if

        //TODO: rebalance soap
    }

    function _calculateDerivativeInterest(uint256 _derivativeId) internal view returns (DataTypes.IporDerivativeInterest memory){
        //iFixed = fixed interest rate * notional amount * T / Ty
        uint256 iFixed = derivatives[_derivativeId].indicator.fixedInterestRate * derivatives[_derivativeId].notionalAmount * YEAR_PER_DERIVATIVE_DEFAULT_PERIOD_IN_SECONDS;
        (, uint256 ibtPrice,) = iporOracle.getIndex(derivatives[_derivativeId].asset);
        //iFloating = IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when derivative is closed)
        uint256 iFloating = derivatives[_derivativeId].indicator.ibtQuantity * ibtPrice;
        int256 interestDifferenceAmount = derivatives[_derivativeId].direction == 0 ? (int256)(iFixed - iFloating) : (int256)(iFloating - iFixed);
        return DataTypes.IporDerivativeInterest(iFixed, iFloating, interestDifferenceAmount);
    }

    function _calculateAbsValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? - value : value);
    }

    function _rebalanceBasedOnInterestDifferenceAmount(uint256 _derivativeId, int256 interestDifferenceAmount) internal {

        uint256 absInterestDifferenceAmount = _calculateAbsValue(interestDifferenceAmount);

        //decrease from balances the liquidation deposit
        require(liquidationDepositFeeTotalBalances[derivatives[_derivativeId].asset] >= derivatives[_derivativeId].fee.liquidationDepositAmount,
            Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDATION_DEPOSIT_BALANCE_IS_TOO_LOW);

        liquidationDepositFeeTotalBalances[derivatives[_derivativeId].asset] = liquidationDepositFeeTotalBalances[derivatives[_derivativeId].asset] - derivatives[_derivativeId].fee.liquidationDepositAmount;
        derivativesTotalBalances[derivatives[_derivativeId].asset] = derivativesTotalBalances[derivatives[_derivativeId].asset] - derivatives[_derivativeId].depositAmount;

        uint256 transferAmount = derivatives[_derivativeId].depositAmount;

        if (msg.sender == derivatives[_derivativeId].buyer) {
            transferAmount = transferAmount + derivatives[_derivativeId].fee.liquidationDepositAmount;
        }

        if (interestDifferenceAmount > 0) {
            //tokens transfered outsite AMM

            if (absInterestDifferenceAmount >= derivatives[_derivativeId].depositAmount) {
                require(liquidityPoolTotalBalances[derivatives[_derivativeId].asset] >= derivatives[_derivativeId].depositAmount, Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);
                //fetch "D" amount from Liquidity Pool
                liquidityPoolTotalBalances[derivatives[_derivativeId].asset] = liquidityPoolTotalBalances[derivatives[_derivativeId].asset] - derivatives[_derivativeId].depositAmount;

                //transfer D+D to user's address
                transferAmount = transferAmount + derivatives[_derivativeId].depositAmount;
                _transferDerivativeAmount(_derivativeId, transferAmount);
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount

            } else {
                require(liquidityPoolTotalBalances[derivatives[_derivativeId].asset] >= absInterestDifferenceAmount, Errors.AMM_CANNOT_CLOSE_DERIVATE_LIQUIDITY_POOL_IS_TOO_LOW);
                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                require(msg.sender == derivatives[_derivativeId].buyer ||
                    block.timestamp > derivatives[_derivativeId].endingTimestamp, Errors.AMM_CANNOT_CLOSE_DERIVATE_CONDITION_NOT_MET);

                //fetch "I" amount from Liquidity Pool
                liquidityPoolTotalBalances[derivatives[_derivativeId].asset] = liquidityPoolTotalBalances[derivatives[_derivativeId].asset] - absInterestDifferenceAmount;

                //transfer P=D+I to user's address
                transferAmount = transferAmount + absInterestDifferenceAmount;
                _transferDerivativeAmount(_derivativeId, transferAmount);
            }

        } else {
            //tokens transfered inside AMM, updates on balances

            if (absInterestDifferenceAmount > derivatives[_derivativeId].depositAmount) {
                //transfer D  to Liquidity Pool
                liquidityPoolTotalBalances[derivatives[_derivativeId].asset] = liquidityPoolTotalBalances[derivatives[_derivativeId].asset] + derivatives[_derivativeId].depositAmount;
                //don't have to verify if sender is an owner of derivative, everyone can close derivative when interest rate value higher or equal deposit amount
            } else {
                //verify if sender is an owner of derivative if not then check if maturity - if not then reject, if yes then close even if not an owner
                require(msg.sender == derivatives[_derivativeId].buyer ||
                    block.timestamp > derivatives[_derivativeId].endingTimestamp, Errors.AMM_CANNOT_CLOSE_DERIVATE_CONDITION_NOT_MET);

                //transfer I to Liquidity Pool
                liquidityPoolTotalBalances[derivatives[_derivativeId].asset] = liquidityPoolTotalBalances[derivatives[_derivativeId].asset] + absInterestDifferenceAmount;

                //transfer D-I to user's address
                transferAmount = transferAmount - absInterestDifferenceAmount;
                _transferDerivativeAmount(_derivativeId, transferAmount);
            }
        }
    }

    function _transferDerivativeAmount(uint256 _derivativeId, uint256 transferAmount) internal {
        derivatives[_derivativeId].state = DataTypes.DerivativeState.INACTIVE;
        IERC20(tokens[derivatives[_derivativeId].asset]).transfer(msg.sender, transferAmount);
        if (msg.sender != derivatives[_derivativeId].buyer) {
            //transfer liquidation deposit to sender
            IERC20(tokens[derivatives[_derivativeId].asset]).transfer(msg.sender, derivatives[_derivativeId].fee.liquidationDepositAmount);
        }
    }

    function provideLiquidity(string memory _asset, uint256 _liquidityAmount) public {
        liquidityPoolTotalBalances[_asset] = liquidityPoolTotalBalances[_asset] + _liquidityAmount;
        IERC20(tokens[_asset]).transferFrom(msg.sender, address(this), _liquidityAmount);
    }

    function _calculcatePayout() internal returns (uint256) {
        return 1e10;
    }

    function _calculateClosingFeeAmount(uint256 depositAmount) internal returns (uint256) {
        return depositAmount * closingFeePercentage / 1e20;
    }

    function _calculateDerivativeAmount(
        uint256 _totalAmount, uint8 _leverage
    ) internal pure returns (DataTypes.IporDerivativeAmount memory) {
        uint256 openingFeeAmount = (_totalAmount - LIQUIDATION_DEPOSIT_FEE_AMOUNT - IPOR_PUBLICATION_FEE_AMOUNT) * OPENING_FEE_PERCENTAGE / 1e18;
        uint256 depositAmount = _totalAmount - LIQUIDATION_DEPOSIT_FEE_AMOUNT - IPOR_PUBLICATION_FEE_AMOUNT - openingFeeAmount;
        return DataTypes.IporDerivativeAmount(
            depositAmount,
            _leverage * depositAmount,
            openingFeeAmount
        );
    }

    function _calculateIbtQuantity(string memory _asset, uint256 _notionalAmount) internal view returns (uint256){
        (, uint256 _ibtPrice,) = iporOracle.getIndex(_asset);
        return _notionalAmount / _ibtPrice;
    }

    //@notice FOR FRONTEND
    function getTotalSupply(string memory _asset) external view returns (uint256) {
        ERC20 token = ERC20(tokens[_asset]);
        return token.balanceOf(address(this));
    }

    //@notice FOR FRONTEND
    function getOpenPositions() external view returns (DataTypes.IporDerivative[] memory) {
        DataTypes.IporDerivative[] memory _derivatives = new DataTypes.IporDerivative[](derivatives.length);

        for (uint256 i = 0; i < derivatives.length; i++) {
            DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
                derivatives[i].indicator.iporIndexValue,
                derivatives[i].indicator.ibtPrice,
                derivatives[i].indicator.ibtQuantity,
                derivatives[i].indicator.fixedInterestRate,
                derivatives[i].indicator.soap
            );

            DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
                derivatives[i].fee.liquidationDepositAmount,
                derivatives[i].fee.openingAmount,
                derivatives[i].fee.iporPublicationAmount,
                derivatives[i].fee.spreadPercentage
            );
            _derivatives[i] = DataTypes.IporDerivative(
                derivatives[i].id,
                derivatives[i].state,
                derivatives[i].buyer,
                derivatives[i].asset,
                derivatives[i].direction,
                derivatives[i].depositAmount,
                fee,
                derivatives[i].leverage,
                derivatives[i].notionalAmount,
                derivatives[i].startingTimestamp,
                derivatives[i].endingTimestamp,
                indicator
            );

        }

        return _derivatives;

    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `3`, a balance of `707` tokens should
     * be displayed to a user as `0,707` (`707 / 10 ** 3`).
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    modifier onlyActiveDerivative(uint256 _derivativeId) {
        require(derivatives[_derivativeId].state == DataTypes.DerivativeState.ACTIVE, Errors.AMM_DERIVATIVE_IS_INACTIVE);
        _;
    }
    /**
     * @notice Modifier which checks if caller is admin for this contract
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, Errors.CALLER_NOT_IPOR_ORACLE_ADMIN);
        _;
    }
}