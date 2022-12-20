// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../amm/spread/MiltonSpreadModelUsdt.sol";

contract MockBaseMiltonSpreadModelUsdt is MiltonSpreadModelUsdt {
    function mockTestCalculateSpreadPremiumsPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance
    ) public view returns (int256 spreadPremiums) {
        IporTypes.MiltonBalancesMemory memory balance = IporTypes.MiltonBalancesMemory(
            totalCollateralPayFixedBalance,
            totalCollateralReceiveFixedBalance,
            liquidityPoolBalance,
            0
        );
        return _calculateSpreadPremiumsPayFixed(accruedIpor, balance);
    }

    function mockTestCalculateSpreadPremiumsRecFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixedBalance,
        uint256 totalCollateralReceiveFixedBalance
    ) public view returns (int256 spreadPremiums) {
        IporTypes.MiltonBalancesMemory memory balance = IporTypes.MiltonBalancesMemory(
            totalCollateralPayFixedBalance,
            totalCollateralReceiveFixedBalance,
            liquidityPoolBalance,
            0
        );
        return _calculateSpreadPremiumsReceiveFixed(accruedIpor, balance);
    }

    function mockTestCalculateVolatilityAndMeanReversionPayFixed(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _calculateVolatilityAndMeanReversionPayFixed(emaVar, diffIporIndexEma);
    }

    function mockTestCalculateVolatilityAndMeanReversionReceiveFixed(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _calculateVolatilityAndMeanReversionReceiveFixed(emaVar, diffIporIndexEma);
    }

    function mockTestVolatilityAndMeanReversionPayFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionPayFixedRegionOne(emaVar, diffIporIndexEma);
    }

    function mockTestVolatilityAndMeanReversionReceiveFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionReceiveFixedRegionOne(emaVar, diffIporIndexEma);
    }

    function mockTestVolatilityAndMeanReversionPayFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionPayFixedRegionTwo(emaVar, diffIporIndexEma);
    }

    function mockTestVolatilityAndMeanReversionReceiveFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, diffIporIndexEma);
    }
}
