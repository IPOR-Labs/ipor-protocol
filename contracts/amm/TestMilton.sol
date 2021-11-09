// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./Milton.sol";

contract TestMilton is Milton {

    function test_openPosition(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor,
        uint8 direction) external returns (uint256) {
        return _openPosition(openTimestamp, asset, totalAmount, maximumSlippage, collateralizationFactor, direction);
    }

    function test_closePosition(uint256 derivativeId, uint256 closeTimestamp) external {
        _closePosition(derivativeId, closeTimestamp);
    }

    function test_calculateSoap(
        address asset,
        uint256 calculateTimestamp) external view returns (int256 soapPf, int256 soapRf, int256 soap){
        return _calculateSoap(asset, calculateTimestamp);
    }

    function test_calculateSpread(
        address asset,
        uint256 calculateTimestamp) external view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue){
        return _calculateSpread(asset, calculateTimestamp);
    }

    function test_calculatePositionValue(
        uint256 calculateTimestamp, DataTypes.IporDerivative memory derivative) external view returns (int256){
        return _calculatePositionValue(calculateTimestamp, derivative);
    }

    function setSpreadPayFixed(address asset, uint256 value) external {
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        iporConfiguration.setSpreadPayFixedValue(value);
    }

    function getSpreadPayFixed(address asset) external view returns (uint256){
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        return iporConfiguration.getSpreadPayFixedValue();
    }

    function setSpreadRecFixed(address asset, uint256 value) external {
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        iporConfiguration.setSpreadRecFixedValue(value);
    }

    function getSpreadRecFixed(address asset) external view returns (uint256){
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        return iporConfiguration.getSpreadRecFixedValue();
    }

}
