// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/Constants.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from '../libraries/AmmMath.sol';

//@notice Milton utilization strategy which - for simplification - is based on Collateral
//(collateral is a total balance of derivatives in Milton)
contract MiltonLPUtilizationStrategyCollateral is IMiltonLPUtilizationStrategy {

    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public {
        _addressesManager = addressesManager;
    }

    function calculateUtilization(address asset, uint256 deposit, uint256 openingFee) external override view returns (uint256) {
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());
        DataTypes.MiltonTotalBalance memory balance = miltonStorage.getBalance(asset);
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));

        if ((balance.liquidityPool + openingFee) != 0) {
            return AmmMath.division((balance.derivatives + deposit) * iporConfiguration.getMultiplicator(), balance.liquidityPool + openingFee);
        } else {
            return Constants.MAX_VALUE;
        }
    }
}
