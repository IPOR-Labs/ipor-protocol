//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "../contracts/mocks/MockDecayFactorCalculation.sol";
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
		bytes memory testDataBytes = json.parseRaw(".data");
		LinearFunctionTestData[] memory rawTestData = abi.decode(abi.encodePacked(testDataBytes), (LinearFunctionTestData[]));
		console.logInt(rawTestData[0].base);
		console.logInt(rawTestData[0].result);
		console.logInt(rawTestData[0].slope);
		console.logInt(rawTestData[0].variable);
		// for (uint256 i = 0; i < rawTestData.length; i++) {
		// 	// console2.log(uint256(rawTestData[i].base));	
		// 	console.logInt(rawTestData[i].base);
		// 	console.logInt(rawTestData[i].result);
		// 	console.logInt(rawTestData[i].slope);
		// 	console.logInt(rawTestData[i].variable);
		// }	
	}
}
