// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "../libraries/Constants.sol";
import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonLPUtilisationStrategy.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from '../libraries/AmmMath.sol';
import "../interfaces/IMiltonSpreadStrategy.sol";

contract MiltonSpreadStrategy is IMiltonSpreadStrategy {

    IIporConfiguration internal _addressesManager;

    function initialize(IIporConfiguration addressesManager) public {
        _addressesManager = addressesManager;
    }

    function calculateSpread(address asset, uint256 calculateTimestamp) external override view returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue) {
        return IMiltonStorage(_addressesManager.getMiltonStorage()).calculateSpread(asset, calculateTimestamp);
    }
}
