// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "../../interfaces/types/IporTypes.sol";


library BaseSpread28DaysLibs {

    function _calculateSpreadPremiumsPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) internal view returns (int256 spreadPremiums) {
        require(
            accruedBalance.liquidityPool > 0,
            MiltonErrors.LIQUIDITY_POOL_ACCRUED_IS_EQUAL_ZERO
        );

        int256 diffIporIndexEma = accruedIpor.indexValue.toInt256() -
        accruedIpor.exponentialMovingAverage.toInt256();

        spreadPremiums = _calculateVolatilityAndMeanReversionPayFixed(
            accruedIpor.exponentialWeightedMovingVariance,
            diffIporIndexEma
        );
    }
}