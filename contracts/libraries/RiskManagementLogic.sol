// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/types/AmmTypes.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../amm/spread/ISpread28DaysLens.sol";
import "../amm/spread/ISpread60DaysLens.sol";
import "../amm/spread/ISpread90DaysLens.sol";
import "./Constants.sol";
import "./errors/AmmErrors.sol";
import "./math/IporMath.sol";

library RiskManagementLogic {
    using Address for address;

    /// @notice Stuct describing the context for calculating the offered rate
    /// @param asset Asset address
    /// @param ammStorage AMM storage address
    /// @param iporRiskManagementOracle IPOR risk management oracle address
    /// @param spreadRouter Spread router address
    /// @param minLeverage Minimum leverage
    /// @param indexValue IPOR Index value
    struct SpreadOfferedRateContext {
        address asset;
        address ammStorage;
        address iporRiskManagementOracle;
        address spreadRouter;
        uint256 minLeverage;
        uint256 indexValue;
    }

    /// @notice Calculates the offered rate
    /// @param direction Swap direction
    /// @param tenor Swap tenor
    /// @param swapNotional Swap notional
    /// @param spreadOfferedRateCtx Context for calculating the offered rate
    /// @return Offered rate
    function calculateOfferedRate(
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        SpreadOfferedRateContext memory spreadOfferedRateCtx
    ) internal view returns (uint256) {
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
                spreadOfferedRateCtx.spreadRouter.functionStaticCall(
                    abi.encodeWithSelector(
                        determineSpreadMethodSig(direction, tenor),
                        spreadOfferedRateCtx.asset,
                        swapNotional,
                        riskIndicators.maxLeveragePerLeg,
                        riskIndicators.maxCollateralRatioPerLeg,
                        riskIndicators.baseSpreadPerLeg,
                        balance.totalCollateralPayFixed,
                        balance.totalCollateralReceiveFixed,
                        balance.liquidityPool,
                        balance.totalNotionalPayFixed,
                        balance.totalNotionalReceiveFixed,
                        spreadOfferedRateCtx.indexValue,
                        riskIndicators.fixedRateCapPerLeg
                    )
                ),
                (uint256)
            );
    }

    /// @notice Gets the risk indicators for an open swap
    /// @param asset Asset address
    /// @param direction Swap direction
    /// @param tenor Swap tenor
    /// @param liquidityPoolBalance Liquidity pool balance
    /// @param cfgMinLeverage Minimum leverage from Protocol configuration
    /// @param cfgIporRiskManagementOracle IPOR risk management oracle address from Protocol configuration
    /// @return riskIndicators Risk indicators
    function getRiskIndicators(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 liquidityPoolBalance,
        uint256 cfgMinLeverage,
        address cfgIporRiskManagementOracle
    ) internal view returns (AmmTypes.OpenSwapRiskIndicators memory riskIndicators) {
        uint256 maxNotionalPerLeg;

        (
            maxNotionalPerLeg,
            riskIndicators.maxCollateralRatioPerLeg,
            riskIndicators.maxCollateralRatio,
            riskIndicators.baseSpreadPerLeg,
            riskIndicators.fixedRateCapPerLeg
        ) = IIporRiskManagementOracle(cfgIporRiskManagementOracle).getOpenSwapParameters(asset, direction, tenor);

        uint256 maxCollateralPerLeg = IporMath.division(
            liquidityPoolBalance * riskIndicators.maxCollateralRatioPerLeg,
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

    /// @notice Determines the spread method signature based on the swap direction and tenor
    /// @param direction Swap direction
    /// @param tenor Swap tenor
    /// @return Spread method signature
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
