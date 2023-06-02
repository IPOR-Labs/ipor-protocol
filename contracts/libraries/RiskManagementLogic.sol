// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IAssetManagement.sol";
import "../governance/AmmConfigurationManager.sol";
import "../amm/libraries/types/AmmInternalTypes.sol";

library RiskManagementLogic {
    using Address for address;

    struct SpreadQuoteContext {
        address asset;
        address ammStorage;
        address iporRiskManagementOracle;
        address spreadRouter;
        uint256 minLeverage;
        uint256 indexValue;
    }

    function calculateQuote(
        uint256 swapNotional,
        uint256 direction,
        uint256 duration,
        SpreadQuoteContext memory spreadQuoteCtx
    ) internal returns (uint256) {
        IporTypes.AmmBalancesForOpenSwapMemory memory balance = IAmmStorage(spreadQuoteCtx.ammStorage)
            .getBalancesForOpenSwap();

        AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicators = getRiskIndicators(
            spreadQuoteCtx.asset,
            direction,
            duration,
            balance.liquidityPool,
            spreadQuoteCtx.minLeverage,
            spreadQuoteCtx.iporRiskManagementOracle
        );

        return
            abi.decode(
                spreadQuoteCtx.spreadRouter.functionCall(
                    abi.encodeWithSignature(
                        determineSpreadMethodSig(direction, duration),
                        spreadQuoteCtx.asset,
                        swapNotional,
                        riskIndicators.maxLeveragePerLeg,
                        riskIndicators.maxCollateralRatioPerLeg,
                        riskIndicators.spread,
                        balance.totalCollateralPayFixed,
                        balance.totalCollateralReceiveFixed,
                        balance.liquidityPool,
                        balance.totalNotionalPayFixed,
                        balance.totalNotionalReceiveFixed,
                        spreadQuoteCtx.indexValue
                    )
                ),
                (uint256)
            );
    }

    function getRiskIndicators(
        address asset,
        uint256 direction,
        uint256 duration,
        uint256 liquidityPool,
        uint256 cfgMinLeverage,
        address cfgIporRiskManagementOracle
    ) internal view returns (AmmInternalTypes.OpenSwapRiskIndicators memory riskIndicators) {
        uint256 maxNotionalPerLeg;
        uint256 maxCollateralRatio;

        (
            maxNotionalPerLeg,
            riskIndicators.maxCollateralRatioPerLeg,
            maxCollateralRatio,
            riskIndicators.spread,
            riskIndicators.fixedRateCap
        ) = IIporRiskManagementOracle(cfgIporRiskManagementOracle).getOpenSwapParameters(asset, direction, duration);

        uint256 maxCollateralPerLeg = IporMath.division(
            liquidityPool * riskIndicators.maxCollateralRatioPerLeg,
            1e18
        );

        if (maxCollateralPerLeg > 0) {
            riskIndicators.maxLeveragePerLeg = _leverageInRange(
                IporMath.division(maxNotionalPerLeg * 1e18, maxCollateralPerLeg),
                cfgMinLeverage
            );
        } else {
            riskIndicators.maxLeveragePerLeg = cfgMinLeverage;
        }
    }

    function determineSpreadMethodSig(uint256 direction, uint256 inputDuration) internal pure returns (string memory) {
        AmmTypes.SwapDuration duration = AmmTypes.SwapDuration(inputDuration);
        if (direction == 0) {
            if (duration == AmmTypes.SwapDuration.DAYS_28) {
                return
                    "calculateOfferedRatePayFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256))";
            } else if (duration == AmmTypes.SwapDuration.DAYS_60) {
                return
                    "calculateOfferedRatePayFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256))";
            } else if (duration == AmmTypes.SwapDuration.DAYS_90) {
                return
                    "calculateOfferedRatePayFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256))";
            } else {
                revert("Invalid duration");
            }
        } else if (direction == 1) {
            if (duration == AmmTypes.SwapDuration.DAYS_28) {
                return
                    "calculateOfferedRateReceiveFixed28Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256))";
            } else if (duration == AmmTypes.SwapDuration.DAYS_60) {
                return
                    "calculateOfferedRateReceiveFixed60Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256))";
            } else if (duration == AmmTypes.SwapDuration.DAYS_90) {
                return
                    "calculateOfferedRateReceiveFixed90Days((address,uint256,uint256,uint256,int256,uint256,uint256,uint256,uint256,uint256,uint256))";
            } else {
                revert("Invalid duration");
            }
        } else {
            revert("Invalid direction");
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
