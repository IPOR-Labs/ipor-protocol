// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../../amm/spread/MiltonSpreadModel.sol";

contract MockBaseMiltonSpreadModel is MiltonSpreadModel {
    function testCalculateSpreadPremiumsPayFixed(
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

    function testCalculateSpreadPremiumsRecFixed(
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

    function testCalculateVolatilityAndMeanReversionPayFixed(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _calculateVolatilityAndMeanReversionPayFixed(emaVar, diffIporIndexEma);
    }

    function testCalculateVolatilityAndMeanReversionReceiveFixed(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _calculateVolatilityAndMeanReversionReceiveFixed(emaVar, diffIporIndexEma);
    }

    function testVolatilityAndMeanReversionPayFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionPayFixedRegionOne(emaVar, diffIporIndexEma);
    }

    function testVolatilityAndMeanReversionReceiveFixedRegionOne(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionReceiveFixedRegionOne(emaVar, diffIporIndexEma);
    }

    function testVolatilityAndMeanReversionPayFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionPayFixedRegionTwo(emaVar, diffIporIndexEma);
    }

    function testVolatilityAndMeanReversionReceiveFixedRegionTwo(
        uint256 emaVar,
        int256 diffIporIndexEma
    ) public view returns (int256) {
        return _volatilityAndMeanReversionReceiveFixedRegionTwo(emaVar, diffIporIndexEma);
    }
}
