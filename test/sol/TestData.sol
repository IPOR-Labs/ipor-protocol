// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../../contracts/libraries/types/DataTypes.sol";
import "../../contracts/libraries/Constants.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

contract TestData {

    uint256 constant PERIOD_1_DAY_IN_SECONDS = 60 * 60 * 24 * 1;
    uint256 constant PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;

    function prepareInitialTotalSoapIndicator(uint256 timestamp) public pure returns (DataTypes.TotalSoapIndicator memory) {
        DataTypes.SoapIndicator memory pfSoapIndicator = prepareInitialSoapIndicator(timestamp, DataTypes.DerivativeDirection.PayFixedReceiveFloating);
        DataTypes.SoapIndicator memory rfSoapIndicator = prepareInitialSoapIndicator(timestamp, DataTypes.DerivativeDirection.PayFloatingReceiveFixed);
        return DataTypes.TotalSoapIndicator(pfSoapIndicator, rfSoapIndicator);
    }

    function prepareInitialSoapIndicator(uint256 timestamp, DataTypes.DerivativeDirection direction) public pure returns (DataTypes.SoapIndicator memory) {
        return DataTypes.SoapIndicator(timestamp, direction, 0, 0, 0, 0, 0);
    }

    function prepareInitialDefaultSoapIndicator(uint256 timestamp) public pure returns (DataTypes.SoapIndicator memory) {
        return DataTypes.SoapIndicator(timestamp, DataTypes.DerivativeDirection.PayFixedReceiveFloating, 0, 0, 0, 0, 0);
    }

    function prepareSoapIndicatorPfCase1() public view returns (DataTypes.SoapIndicator memory) {
        return prepareSoapIndicatorCase1(DataTypes.DerivativeDirection.PayFixedReceiveFloating);
    }

    function prepareSoapIndicatorRfCase1() public view returns (DataTypes.SoapIndicator memory) {
        return prepareSoapIndicatorCase1(DataTypes.DerivativeDirection.PayFloatingReceiveFixed);
    }

    function prepareSoapIndicatorCase1(DataTypes.DerivativeDirection direction) public view returns (DataTypes.SoapIndicator memory) {
        uint256 totalNotional = 20000 * 1e18;
        uint256 averageInterestRate = 8 * 1e16;
        uint256 totalIbtQuantity = 100 * 1e18;
        uint256 hypotheticalInterestCumulativeNumerator = 500 * 1e54 * Constants.YEAR_IN_SECONDS;

        DataTypes.SoapIndicator memory soapIndicator = DataTypes.SoapIndicator(
            block.timestamp,
            direction,
            hypotheticalInterestCumulativeNumerator,
            totalNotional,
            averageInterestRate,
            totalIbtQuantity,
            0
        );

        return soapIndicator;
    }

    function assertSoapIndicator(
        DataTypes.SoapIndicator memory si,
        uint256 expectedRebalanceTimestamp,
        uint256 expectedTotalNotional,
        uint256 expectedTotalIbtQuantity,
        uint256 expectedAverageInterestRate,
        uint256 expectedQuasiHypotheticalInterestCumulative
    ) public {
        Assert.equal(si.rebalanceTimestamp, expectedRebalanceTimestamp, 'Incorrect rebalance timestamp');
        Assert.equal(si.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(si.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(si.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(si.quasiHypotheticalInterestCumulative, expectedQuasiHypotheticalInterestCumulative, 'Incorrect quasi hypothetical interest cumulative');
    }

    /*
    * @param fixedInterestRate is a spread with IPOR index
    */
    function prepareDerivativeCase1(uint256 fixedInterestRate) public view returns (DataTypes.IporDerivative memory) {

        uint256 ibtPriceFirst = 100 * Constants.MD;
        uint256 depositAmount = 9870300000000000000000;
        uint256 collateralization = 10;

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes.IporDerivativeIndicator(
            3 * 1e16, //ipor index value
            ibtPriceFirst,
            987030000000000000000, //ibtQuantity
            fixedInterestRate
        );

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            20 * Constants.MD, //liquidation deposit amount
            99700000000000000000, //opening fee amount
            10 * Constants.MD, //ipor publication amount
            1e16 // spread percentege
        );

        DataTypes.IporDerivative memory derivative = DataTypes.IporDerivative(
            0,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            "DAI",
            0, //Pay Fixed, Receive Floating (long position)
            depositAmount,
            fee, collateralization,
            depositAmount * collateralization,
            block.timestamp,
            block.timestamp + 60 * 60 * 24 * 28,
            indicator
        );

        return derivative;

    }
}