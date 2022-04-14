// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./MockBaseMiltonSpreadModel.sol";

contract MockCase10MiltonSpreadModel is MockBaseMiltonSpreadModel {
    function _getSpreadPremiumsMaxValue() internal pure virtual override returns (uint256) {
        return 300000000000000000;
    }

    function _getDCKfValue() internal pure virtual override returns (uint256) {
        return 1000000000000000;
    }

    function _getDCLambdaValue() internal pure virtual override returns (uint256) {
        return 30000000000000000;
    }

    function _getDCKOmegaValue() internal pure virtual override returns (uint256) {
        return 30000000000000000;
    }

    function _getDCMaxLiquidityRedemptionValue() internal pure virtual override returns (uint256) {
        return 1000000000000000000;
    }

}
