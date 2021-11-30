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
}
