// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import { AmmMath } from "../libraries/AmmMath.sol";

//@notice Milton utilization strategy which - for simplification - is based on Collateral
//(collateral is a total balance of derivatives in Milton)
contract MiltonLPUtilizationStrategyCollateral is IMiltonLPUtilizationStrategy {
    IIporConfiguration internal iporConfiguration;

    //TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration) external {
        iporConfiguration = initialIporConfiguration;
    }

    function calculateTotalUtilizationRate(
        address asset,
        uint256 deposit,
        uint256 openingFee,
        uint256 multiplicator
    ) external view override returns (uint256) {
        IMiltonStorage miltonStorage = IMiltonStorage(
            iporConfiguration.getMiltonStorage()
        );
        DataTypes.MiltonTotalBalance memory balance = miltonStorage.getBalance(
            asset
        );

        if ((balance.liquidityPool + openingFee) != 0) {
            return
                AmmMath.division(
                    (balance.payFixedDerivatives +
                        balance.recFixedDerivatives +
                        deposit) * multiplicator,
                    balance.liquidityPool + openingFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
