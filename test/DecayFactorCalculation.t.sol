//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "forge-std/StdJson.sol";
import "../contracts/mocks/MockDecayFactorCalculation.sol";

contract DecayFactorCalculationTest is TestCommons {
	using stdJson for string;

	MockDecayFactorCalculation internal _mockDecayFactorCalculation;
    
	struct LinearFunctionTestData {
		int256 base;
		int256 result;
		int256 slope;
		int256 variable;
	}

    function setUp() public {
		_mockDecayFactorCalculation = new MockDecayFactorCalculation();
    }

	function testShouldEvaluateLinearFunction() public {
		string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/asset/testDataForLinearFunction.json");
        string memory json = vm.readFile(path);
		bytes memory testDataBytes = json.parseRaw(".data");
		LinearFunctionTestData[] memory rawTestData = abi.decode(abi.encodePacked(testDataBytes), (LinearFunctionTestData[]));
		for (uint256 i = 0; i < rawTestData.length; i++) {
			LinearFunctionTestData memory testData = rawTestData[i];
			int256 result = _mockDecayFactorCalculation.linearFunction(testData.slope, testData.base, testData.variable);
			assertEq(result, testData.result);	
		}	
	}
}
