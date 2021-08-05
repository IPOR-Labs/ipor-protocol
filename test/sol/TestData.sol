// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../../contracts/libraries/types/DataTypes.sol";
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
        uint256 hypotheticalInterestCumulative = 500 * 1e18;

        DataTypes.SoapIndicator memory soapIndicator = DataTypes.SoapIndicator(
            block.timestamp,
            direction,
            hypotheticalInterestCumulative,
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
        uint256 expectedHypotheticalInterestCumulative
    ) public {
        Assert.equal(si.rebalanceTimestamp, expectedRebalanceTimestamp, 'Incorrect rebalance timestamp');
        Assert.equal(si.totalNotional, expectedTotalNotional, 'Incorrect total notional');
        Assert.equal(si.totalIbtQuantity, expectedTotalIbtQuantity, 'Incorrect total IBT quantity');
        Assert.equal(si.averageInterestRate, expectedAverageInterestRate, 'Incorrect average weighted interest rate');
        Assert.equal(si.hypotheticalInterestCumulative, expectedHypotheticalInterestCumulative, 'Incorrect hypothetical interest cumulative');
    }
}