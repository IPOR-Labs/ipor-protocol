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
    IIporConfiguration internal _iporConfiguration;

	constructor(address initialIporConfiguration) {
		require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
	}

    function calculateTotalUtilizationRate(
        address asset,
        uint256 deposit,
        uint256 openingFee
    ) external view override returns (uint256) {
		//TODO: do in better way
		IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        IMiltonStorage miltonStorage = IMiltonStorage(
            assetConfiguration.getMiltonStorage()
        );
        DataTypes.MiltonTotalBalanceMemory memory balance = miltonStorage.getBalance();

        if ((balance.liquidityPool + openingFee) != 0) {
            return
                IporMath.division(
                    (balance.payFixedDerivatives +
                        balance.recFixedDerivatives +
                        deposit) * Constants.D18,
                    balance.liquidityPool + openingFee
                );
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
