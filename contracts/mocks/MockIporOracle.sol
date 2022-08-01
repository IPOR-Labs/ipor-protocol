// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

import "../itf/ItfIporOracle.sol";

contract MockItfIporOracle is ItfIporOracle {
    function getAccruedIndex(uint256 calculateTimestamp, address asset)
        external
        view
        override
        returns (IporTypes.AccruedIpor memory accruedIpor)
    {
        IporOracleTypes.IPOR memory ipor = _indexes[asset];
        require(ipor.quasiIbtPrice > 0, IporOracleErrors.ASSET_NOT_SUPPORTED);

        accruedIpor = IporTypes.AccruedIpor(
            ipor.indexValue,
            0,
            ipor.exponentialMovingAverage,
            ipor.exponentialWeightedMovingVariance
        );
    }
}
