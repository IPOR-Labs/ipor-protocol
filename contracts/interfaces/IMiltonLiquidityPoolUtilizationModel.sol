// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IMiltonLiquidityPoolUtilizationModel {
    //@notice deposit and openingFee is for this particular swap
    function calculateUtilizationRate(
        uint256 liquidityPoolBalance,
		uint256 totalCollateralBalance,
        uint256 collateral,
        uint256 openingFee
    ) external view returns (uint256);
}
