// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

import "contracts/interfaces/types/AmmTypes.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/interfaces/IIporRiskManagementOracle.sol";
import "contracts/interfaces/IAssetManagement.sol";
import "contracts/amm/spread/ISpread28DaysLens.sol";
import "contracts/amm/spread/ISpread60DaysLens.sol";
import "contracts/amm/spread/ISpread90DaysLens.sol";
import "contracts/libraries/Constants.sol";
import "contracts/libraries/errors/AmmErrors.sol";
import "contracts/libraries/math/IporMath.sol";
import "contracts/governance/AmmConfigurationManager.sol";

library RiskManagementLogic {
    using Address for address;

    struct SpreadOfferedRateContext {
        address asset;
        address ammStorage;
        address iporRiskManagementOracle;
        address spreadRouter;
        uint256 minLeverage;
        uint256 indexValue;
    }

    function calculateOfferedRate(
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        SpreadOfferedRateContext memory spreadOfferedRateCtx
    ) internal returns (uint256) {
        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(spreadOfferedRateCtx.ammStorage)
            .getBalancesForOpenSwap();

        AmmTypes.OpenSwapRiskIndicators memory riskIndicators = getRiskIndicators(
            spreadOfferedRateCtx.asset,
            direction,
            tenor,
            balance.liquidityPool,
            spreadOfferedRateCtx.minLeverage,
            spreadOfferedRateCtx.iporRiskManagementOracle
        );

        return
            abi.decode(
                spreadOfferedRateCtx.spreadRouter.functionCall(
                    abi.encodeWithSelector(
                        determineSpreadMethodSig(direction, tenor),
                        spreadOfferedRateCtx.asset,
                        swapNotional,
                        riskIndicators.maxLeveragePerLeg,
                        riskIndicators.maxCollateralRatioPerLeg,
                        riskIndicators.baseSpread,
                        balance.totalCollateralPayFixed,
                        balance.totalCollateralReceiveFixed,
                        balance.liquidityPool,
                        balance.totalNotionalPayFixed,
                        balance.totalNotionalReceiveFixed,
                        spreadOfferedRateCtx.indexValue,
                        riskIndicators.fixedRateCap
                    )
                ),
                (uint256)
            );
    }

    function getRiskIndicators(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 liquidityPool,
        uint256 cfgMinLeverage,
        address cfgIporRiskManagementOracle
    ) internal view returns (AmmTypes.OpenSwapRiskIndicators memory riskIndicators) {
        uint256 maxNotionalPerLeg;

        (
            maxNotionalPerLeg,
            riskIndicators.maxCollateralRatioPerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.baseSpread,
            riskIndicators.fixedRateCap
        ) = IIporRiskManagementOracle(cfgIporRiskManagementOracle).getOpenSwapParameters(asset, direction, tenor);

        uint256 maxCollateralPerLeg = IporMath.division(liquidityPool * riskIndicators.maxCollateralRatioPerLeg, 1e18);

        if (maxCollateralPerLeg > 0) {
            riskIndicators.maxLeveragePerLeg = _leverageInRange(
                IporMath.division(maxNotionalPerLeg * 1e18, maxCollateralPerLeg),
                cfgMinLeverage
            );
        } else {
            riskIndicators.maxLeveragePerLeg = cfgMinLeverage;
        }
    }

    function determineSpreadMethodSig(uint256 direction, IporTypes.SwapTenor tenor) internal pure returns (bytes4) {
        if (direction == 0) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                return ISpread28DaysLens.calculateOfferedRatePayFixed28Days.selector;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                return ISpread60DaysLens.calculateOfferedRatePayFixed60Days.selector;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                return ISpread90DaysLens.calculateOfferedRatePayFixed90Days.selector;
            } else {
                revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
            }
        } else if (direction == 1) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                return ISpread28DaysLens.calculateOfferedRateReceiveFixed28Days.selector;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                return ISpread60DaysLens.calculateOfferedRateReceiveFixed60Days.selector;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                return ISpread90DaysLens.calculateOfferedRateReceiveFixed90Days.selector;
            } else {
                revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
            }
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }
    }

    function _leverageInRange(uint256 leverage, uint256 cfgMinLeverage) private pure returns (uint256) {
        if (leverage > Constants.WAD_LEVERAGE_1000) {
            return Constants.WAD_LEVERAGE_1000;
        } else if (leverage < cfgMinLeverage) {
            return cfgMinLeverage;
        } else {
            return leverage;
        }
    }
}
