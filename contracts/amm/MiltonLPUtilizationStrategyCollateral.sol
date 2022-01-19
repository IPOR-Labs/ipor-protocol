// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/Constants.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import {IporMath} from "../libraries/IporMath.sol";
import {IporErrors} from "../IporErrors.sol";

//@notice Milton utilization strategy which - for simplification - is based on Collateral
//(collateral is a total balance of derivatives in Milton)
contract MiltonLPUtilizationStrategyCollateral is IMiltonLPUtilizationStrategy {

    function calculateTotalUtilizationRate(
		uint256 liquidityPoolBalance,
		uint256 swapsPayFixedBalance,
		uint256 swapsReceiveFixedBalance,
        uint256 collateral,
        uint256 openingFee 
    ) external pure override returns (uint256) {
        if ((liquidityPoolBalance + openingFee) != 0) {
            return
                IporMath.division(
                    (swapsPayFixedBalance +
                        swapsReceiveFixedBalance +
                        collateral) * Constants.D18,
						liquidityPoolBalance + openingFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
