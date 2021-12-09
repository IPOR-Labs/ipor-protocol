// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonLPUtilizationStrategy {
    //@notice deposit and openingFee is for this particular derivative
    function calculateTotalUtilizationRate(
        address asset,
        uint256 deposit,
        uint256 openingFee
    ) external view returns (uint256);
}
