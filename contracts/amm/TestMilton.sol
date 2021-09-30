// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./Milton.sol";

contract TestMilton is Milton {

    function test_openPosition(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralization,
        uint8 direction) public returns (uint256) {
        return _openPosition(openTimestamp, asset, totalAmount, maximumSlippage, collateralization, direction);
    }

    function test_closePosition(uint256 derivativeId, uint256 closeTimestamp) public {
        _closePosition(derivativeId, closeTimestamp);
    }

    function test_calculateSoap(
        address asset,
        uint256 calculateTimestamp) public view returns (int256 soapPf, int256 soapRf, int256 soap){
        return _calculateSoap(asset, calculateTimestamp);
    }

    function test_calculateSpread(
        address asset,
        uint256 calculateTimestamp) public view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue){
        return _calculateSpread(asset, calculateTimestamp);
    }

    function setSpreadPayFixed(address asset, uint256 value) public {
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        miltonConfiguration.setSpreadPayFixedValue(asset, value);
    }

    function getSpreadPayFixed(address asset) public view returns (uint256){
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        return miltonConfiguration.getSpreadPayFixedValue(asset);
    }

    function setSpreadRecFixed(address asset, uint256 value) public {
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        miltonConfiguration.setSpreadRecFixedValue(asset, value);
    }

    function getSpreadRecFixed(address asset) public view returns (uint256){
        IMiltonConfiguration miltonConfiguration = IMiltonConfiguration(_addressesManager.getMiltonConfiguration());
        return miltonConfiguration.getSpreadRecFixedValue(asset);
    }

}
