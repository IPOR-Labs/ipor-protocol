// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./MockBaseMiltonSpreadModel.sol";

contract MockCase8MiltonSpreadModel is MockBaseMiltonSpreadModel {
    function _getSpreadPremiumsMaxValue() internal pure virtual override returns (uint256) {
        return 300000000000000000;
    }

    function _getDCKfValue() internal pure virtual override returns (uint256) {
        return 1000000000000000;
    }

    function _getDCLambdaValue() internal pure virtual override returns (uint256) {
        return 300000000000000000;
    }

    function _getDCKOmegaValue() internal pure virtual override returns (uint256) {
        return 300000000000000000;
    }

    function _getDCMaxLiquidityRedemptionValue() internal pure virtual override returns (uint256) {
        return 692410119840213050;
    }

}
