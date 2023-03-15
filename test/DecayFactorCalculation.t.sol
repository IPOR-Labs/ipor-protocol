//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "../contracts/mocks/MockDecayFactorCalculation.sol";
import "forge-std/console2.sol";
import "forge-std/StdJson.sol";

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
		bytes memory testData = vm.parseJson(json, "data");
		LinearFunctionTestData[] memory data = new LinearFunctionTestData[](testData.length);
		for (uint256 i = 0; i < testData.length; i++) {
			bytes memory testDataItem = abi.encodePacked(testData[i]);
		}
	}
}
