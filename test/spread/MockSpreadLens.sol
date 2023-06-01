// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/amm/spread/ISpread28DaysLens.sol";

contract MockSpreadLens is ISpread28DaysLens {
    function getSupportedAssets() external view returns (address[] memory) {
        return new address[](0);
    }

    function spreadFunction28DaysConfig() public pure returns (uint256[] memory) {
        uint256[] memory mock = new uint256[](20);
        return mock;
    }


    function calculateOfferedRatePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view returns (uint256 spreadValue) {
        spreadValue = 1;
    }

    function calculateOfferedRateReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view returns (uint256 spreadValue) {
        spreadValue = 2;
    }
}
