// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./Milton.sol";

//TODO:  move to mock/test/itf folder
contract TestMilton is Milton {

	//TODO: change name to openPosition, align ITF 
	function test_openPosition(
        uint256 openTimestamp,
        address asset,
        uint256 totalAmount,
        uint256 maximumSlippage,
        uint256 collateralizationFactor,
        uint8 direction
    ) external returns (uint256) {
        return
            _openPosition(
                openTimestamp,
                asset,
                totalAmount,
                maximumSlippage,
                collateralizationFactor,
                direction
            );
    }

	//TODO: change name to closePosition, align ITF 
    function test_closePosition(uint256 derivativeId, uint256 closeTimestamp)
        external
    {
        _closePosition(derivativeId, closeTimestamp);
    }

	//TODO: change name to calculateSoap, align ITF 
    function test_calculateSoap(address asset, uint256 calculateTimestamp)
        external
        view
        returns (
            int256 soapPf,
            int256 soapRf,
            int256 soap
        )
    {
        return _calculateSoap(asset, calculateTimestamp);
    }

	//TODO: change name to calculateSpread, align ITF 
    function test_calculateSpread(address asset, uint256 calculateTimestamp)
        external
        view
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
		spreadPayFixedValue = AmmMath.division(Constants.D18, 100);
		spreadRecFixedValue = AmmMath.division(Constants.D18, 100);
    }

	//TODO: change name to calculatePositionValue, align ITF 
    function test_calculatePositionValue(
        uint256 calculateTimestamp,
        DataTypes.IporDerivative memory derivative
    ) external view returns (int256) {
        return _calculatePositionValue(calculateTimestamp, derivative);
    }

}
