// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import { AmmMath } from "../libraries/AmmMath.sol";
import "../interfaces/IMiltonSpreadStrategy.sol";

contract MiltonSpreadStrategy is IMiltonSpreadStrategy {
    IIporConfiguration internal iporConfiguration;

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration) external {
        iporConfiguration = initialIporConfiguration;
    }

    function calculateSpread(address asset, uint256 calculateTimestamp)
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        return
            IMiltonStorage(iporConfiguration.getMiltonStorage())
                .calculateSpread(asset, calculateTimestamp);
    }

    function calculateDemandComponentPayFixed(
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 multiplicator
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kf = iporAssetConfiguration
            .getSpreadUtilizationComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadUtilizationComponentLambdaValue();

        return
            AmmMath.division(
                kf * multiplicator,
                multiplicator -
                    calculatePayFixedAdjustedUtilizationRate(
                        derivativeDeposit,
                        derivativeOpeningFee,
                        liquidityPool,
                        payFixedDerivativesBalance,
                        recFixedDerivativesBalance,
                        multiplicator,
                        lambda
                    )
            );
    }

    function calculateDemandComponentRecFixed(
        address asset,
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 multiplicator
    ) external view returns (uint256) {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        uint256 kf = iporAssetConfiguration
            .getSpreadUtilizationComponentKfValue();

        uint256 lambda = iporAssetConfiguration
            .getSpreadUtilizationComponentLambdaValue();

        return
            AmmMath.division(
                kf * multiplicator,
                multiplicator -
                    calculateRecFixedAdjustedUtilizationRate(
                        derivativeDeposit,
                        derivativeOpeningFee,
                        liquidityPool,
                        payFixedDerivativesBalance,
                        recFixedDerivativesBalance,
                        multiplicator,
                        lambda
                    )
            );
    }

    //URlambda_leg(M0)
    function calculatePayFixedAdjustedUtilizationRate(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 multiplicator,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRateRecFixed = calculateUtilizationRateWithoutPosition(
                derivativeOpeningFee,
                liquidityPool,
                recFixedDerivativesBalance,
                multiplicator
            );

        uint256 utilizationRatePayFixedWithPosition = calculateUtilizationRateWithPosition(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                multiplicator
            );

        return
            calculateImbalanceFactorWithLambda(
                utilizationRatePayFixedWithPosition,
                utilizationRateRecFixed,
                multiplicator,
                lambda
            );
    }

    function calculateRecFixedAdjustedUtilizationRate(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPool,
        uint256 payFixedDerivativesBalance,
        uint256 recFixedDerivativesBalance,
        uint256 multiplicator,
        uint256 lambda
    ) internal pure returns (uint256) {
        uint256 utilizationRatePayFixed = calculateUtilizationRateWithoutPosition(
                derivativeOpeningFee,
                liquidityPool,
                payFixedDerivativesBalance,
                multiplicator
            );

        uint256 utilizationRateRecFixedWithPosition = calculateUtilizationRateWithPosition(
                derivativeDeposit,
                derivativeOpeningFee,
                liquidityPool,
                recFixedDerivativesBalance,
                multiplicator
            );
        uint256 adjustedUtilizationRate = calculateImbalanceFactorWithLambda(
            utilizationRateRecFixedWithPosition,
            utilizationRatePayFixed,
            multiplicator,
            lambda
        );

        return adjustedUtilizationRate;
    }

    function calculateImbalanceFactorWithLambda(
        uint256 utilizationRateLegWithPosition,
        uint256 utilizationRateLegWithoutPosition,
        uint256 multiplicator,
        uint256 lambda
    ) internal pure returns (uint256) {
        if (
            utilizationRateLegWithPosition >= utilizationRateLegWithoutPosition
        ) {
            return multiplicator - utilizationRateLegWithPosition;
        } else {
            return
                multiplicator -
                (utilizationRateLegWithPosition -
                    AmmMath.division(
                        lambda *
                            (utilizationRateLegWithoutPosition -
                                utilizationRateLegWithPosition),
                        multiplicator
                    ));
        }
    }

    //@notice Calculates utilization rate including position which is opened
    function calculateUtilizationRateWithPosition(
        uint256 derivativeDeposit,
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance,
        uint256 multiplicator
    ) internal pure returns (uint256) {
        if ((liquidityPoolBalance + derivativeOpeningFee) != 0) {
            return
                AmmMath.division(
                    (derivativesBalance + derivativeDeposit) * multiplicator,
                    liquidityPoolBalance + derivativeOpeningFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }

    //URleg(0)
    function calculateUtilizationRateWithoutPosition(
        uint256 derivativeOpeningFee,
        uint256 liquidityPoolBalance,
        uint256 derivativesBalance,
        uint256 multiplicator
    ) internal pure returns (uint256) {
        if (liquidityPoolBalance != 0) {
            return
                AmmMath.division(
                    derivativesBalance * multiplicator,
                    liquidityPoolBalance + derivativeOpeningFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
