// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "../contracts/mocks/MockDecayFactorCalculation.sol";

contract DecayFactorCalculationTest is TestCommons {
	   
	MockDecayFactorCalculation internal _mockDecayFactorCalculation;
    
	struct LinearFunctionTestData {
		int256 slope;
		int256 base;
		int256 variable;
		int256 result;
	}

    function setUp() public {
		_mockDecayFactorCalculation = new MockDecayFactorCalculation();
    }

	function testShouldEvaluateLinearFunction(LinearFunctionTestData memory linearFunctionTestData) public {
		// given
		int256 slope = linearFunctionTestData.slope;
		int256 base = linearFunctionTestData.base;
		int256 variable = linearFunctionTestData.variable;
		int256 result = linearFunctionTestData.result;
		// when 
		int256 decayFactor = _mockDecayFactorCalculation.linearFunction(slope, base, variable);
		// then 
		assertEq(decayFactor, result);
	}

}
