// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonLPUtilizationStrategy {
    //@notice deposit and openingFee is for this particular derivative
    function calculateTotalUtilizationRate(
        address asset,
        uint256 deposit,
        uint256 openingFee,
        uint256 multiplicator
    ) external view returns (uint256);

    // function calculatePayFixedAdjustedUtilizationRate(
    //     uint256 deposit,
    //     uint256 openingFee,
    //     uint256 liquidityPool,
    //     uint256 payFixedDerivativesBalance,
    //     uint256 recFixedDerivativesBalance,
    //     uint256 multiplicator,
    //     uint256 lambda
    // ) external pure returns (uint256);

    // function calculateRecFixedAdjustedUtilizationRate(
    //     uint256 deposit,
    //     uint256 openingFee,
    //     uint256 liquidityPool,
    //     uint256 payFixedDerivativesBalance,
    //     uint256 recFixedDerivativesBalance,
    //     uint256 multiplicator,
    //     uint256 lambda
    // ) external pure returns (uint256);

    // function calculateRecFixedUtilizationRate(
    //     address asset,
    //     uint256 deposit,
    //     uint256 openingFee,
    //     uint256 multiplicator
    // ) external view returns (uint256);

    // function calculateRecFixedAdjustedUtilizationRate(
    //     address asset,
    //     uint256 deposit,
    //     uint256 openingFee,
    //     uint256 multiplicator
    // ) external view returns (uint256);
}
