// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../contracts/libraries/types/DataTypes.sol";
import "../../contracts/libraries/Constants.sol";
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";

contract TestData {
    uint256 constant PERIOD_1_DAY_IN_SECONDS = 60 * 60 * 24 * 1;
    uint256 constant PERIOD_25_DAYS_IN_SECONDS = 60 * 60 * 24 * 25;
    DaiMockedToken daiMockedToken = new DaiMockedToken(1e18, 18);

    function prepareInitialTotalSoapIndicator(uint256 timestamp)
        public
        pure
        returns (DataTypes.TotalSoapIndicator memory)
    {
        DataTypes.SoapIndicator
            memory pfSoapIndicator = prepareInitialSoapIndicator(
                timestamp,
                DataTypes.DerivativeDirection.PayFixedReceiveFloating
            );
        DataTypes.SoapIndicator
            memory rfSoapIndicator = prepareInitialSoapIndicator(
                timestamp,
                DataTypes.DerivativeDirection.PayFloatingReceiveFixed
            );
        return DataTypes.TotalSoapIndicator(pfSoapIndicator, rfSoapIndicator);
    }

    function prepareInitialSoapIndicator(
        uint256 timestamp,
        DataTypes.DerivativeDirection direction
    ) public pure returns (DataTypes.SoapIndicator memory) {
        return DataTypes.SoapIndicator(timestamp, direction, 0, 0, 0, 0, 0);
    }

    function prepareInitialDefaultSoapIndicator(uint256 timestamp)
        public
        pure
        returns (DataTypes.SoapIndicator memory)
    {
        return
            DataTypes.SoapIndicator(
                timestamp,
                DataTypes.DerivativeDirection.PayFixedReceiveFloating,
                0,
                0,
                0,
                0,
                0
            );
    }

    function prepareSoapIndicatorPfCaseD18()
        public
        view
        returns (DataTypes.SoapIndicator memory)
    {
        return
            prepareSoapIndicatorCaseD18(
                DataTypes.DerivativeDirection.PayFixedReceiveFloating
            );
    }

    function prepareSoapIndicatorPfCaseD6()
        public
        view
        returns (DataTypes.SoapIndicator memory)
    {
        return
            prepareSoapIndicatorCaseD6(
                DataTypes.DerivativeDirection.PayFixedReceiveFloating
            );
    }

    function prepareSoapIndicatorRfCaseD18()
        public
        view
        returns (DataTypes.SoapIndicator memory)
    {
        return
            prepareSoapIndicatorCaseD18(
                DataTypes.DerivativeDirection.PayFloatingReceiveFixed
            );
    }

    function prepareSoapIndicatorRfCaseD6()
        public
        view
        returns (DataTypes.SoapIndicator memory)
    {
        return
            prepareSoapIndicatorCaseD6(
                DataTypes.DerivativeDirection.PayFloatingReceiveFixed
            );
    }

    function prepareSoapIndicatorCaseD18(
        DataTypes.DerivativeDirection direction
    ) public view returns (DataTypes.SoapIndicator memory) {
        uint256 totalNotional = 20000 * Constants.D18;
        uint256 averageInterestRate = 8 * 1e16;
        uint256 totalIbtQuantity = 100 * Constants.D18;
        uint256 hypotheticalInterestCumulativeNumerator = 500 *
            Constants.D18 *
            Constants.D18 *
            Constants.D18 *
            Constants.YEAR_IN_SECONDS;

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

    function prepareSoapIndicatorCaseD6(DataTypes.DerivativeDirection direction)
        public
        view
        returns (DataTypes.SoapIndicator memory)
    {
        uint256 totalNotional = 20000 * Constants.D6;
        uint256 averageInterestRate = 8 * 1e4;
        uint256 totalIbtQuantity = 100 * Constants.D6;
        uint256 hypotheticalInterestCumulativeNumerator = 500 *
            Constants.D6 *
            Constants.D6 *
            Constants.D6 *
            Constants.YEAR_IN_SECONDS;

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
        Assert.equal(
            si.rebalanceTimestamp,
            expectedRebalanceTimestamp,
            "Incorrect rebalance timestamp"
        );
        Assert.equal(
            si.totalNotional,
            expectedTotalNotional,
            "Incorrect total notional"
        );
        Assert.equal(
            si.totalIbtQuantity,
            expectedTotalIbtQuantity,
            "Incorrect total IBT quantity"
        );
        Assert.equal(
            si.averageInterestRate,
            expectedAverageInterestRate,
            "Incorrect average weighted interest rate"
        );
        Assert.equal(
            si.quasiHypotheticalInterestCumulative,
            expectedQuasiHypotheticalInterestCumulative,
            "Incorrect quasi hypothetical interest cumulative"
        );
    }

    /*
     * @param fixedInterestRate is a spread with IPOR index
     */
    function prepareDerivativeCase1(uint256 fixedInterestRate)
        public
        view
        returns (DataTypes.IporDerivative memory)
    {
        uint256 ibtPriceFirst = 100 * Constants.D18;
        uint256 collateral = 9870300000000000000000;
        uint256 collateralizationFactor = 10;

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes
            .IporDerivativeIndicator(
                3 * 1e16, //ipor index value
                ibtPriceFirst,
                987030000000000000000, //ibtQuantity
                fixedInterestRate
            );

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            20 * Constants.D18, //liquidation deposit amount
            99700000000000000000, //opening fee amount
            10 * Constants.D18, //ipor publication amount
            1e16, // spread percentege
            1e16 // spread percentege
        );

        DataTypes.IporDerivative memory derivative = DataTypes.IporDerivative(
            0,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            address(daiMockedToken),
            0, //Pay Fixed, Receive Floating (long position)
            collateral,
            fee,
            collateralizationFactor,
            collateral * collateralizationFactor,
            block.timestamp,
            block.timestamp + 60 * 60 * 24 * 28,
            indicator,
            Constants.D18
        );

        return derivative;
    }

    function prepareDerivativeCase2(uint256 fixedInterestRate)
        public
        view
        returns (DataTypes.IporDerivative memory)
    {
        uint256 ibtPriceFirst = 100 * Constants.D6;
        uint256 collateral = 9870300000;
        uint256 collateralizationFactor = 10;

        DataTypes.IporDerivativeIndicator memory indicator = DataTypes
            .IporDerivativeIndicator(
                3 * 1e4, //ipor index value
                ibtPriceFirst,
                987030000, //ibtQuantity
                fixedInterestRate
            );

        DataTypes.IporDerivativeFee memory fee = DataTypes.IporDerivativeFee(
            20 * Constants.D6, //liquidation deposit amount
            99700000, //opening fee amount
            10 * Constants.D6, //ipor publication amount
            1e4, // spread percentege
            1e4 // spread percentege
        );

        DataTypes.IporDerivative memory derivative = DataTypes.IporDerivative(
            0,
            DataTypes.DerivativeState.ACTIVE,
            msg.sender,
            address(daiMockedToken),
            0, //Pay Fixed, Receive Floating (long position)
            collateral,
            fee,
            collateralizationFactor,
            collateral * collateralizationFactor,
            block.timestamp,
            block.timestamp + 60 * 60 * 24 * 28,
            indicator,
            Constants.D6
        );

        return derivative;
    }
}
