// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";

interface IMiltonLiquidityPoolUtilizationModel {
    //@notice deposit and openingFee is for this particular derivative
    function calculateTotalUtilizationRate(
        uint256 liquidityPoolBalance,
		uint256 swapsPayFixedBalance,
		uint256 swapsReceiveFixedBalance,
        uint256 collateral,
        uint256 openingFee
    ) external view returns (uint256);
}
