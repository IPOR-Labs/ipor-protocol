//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "contracts/oracles/libraries/DecayFactorCalculation.sol";

contract DecayFactorCalculationTest is TestCommons {
    using stdJson for string;

    struct LinearFunctionTestData {
        int256 base;
        int256 result;
        int256 slope;
        int256 variable;
    }

    function testShouldEvaluateLinearFunction() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/asset/testDataForLinearFunction.json");
        console2.log(path);
        string memory json = vm.readFile(path);
        bytes memory testDataBytes = json.parseRaw(".data");
        LinearFunctionTestData[] memory rawTestData = abi.decode(
            abi.encodePacked(testDataBytes),
            (LinearFunctionTestData[])
        );
        for (uint256 i = 0; i < rawTestData.length; i++) {
            LinearFunctionTestData memory testData = rawTestData[i];
            int256 result = DecayFactorCalculation.linearFunction(testData.slope, testData.base, testData.variable);
            assertEq(result, testData.result);
        }
    }
}
