// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "../../libraries/Constants.sol";
import "../../libraries/errors/IporOracleErrors.sol";
import "../../libraries/errors/AmmErrors.sol";
import "../../interfaces/types/IporOracleTypes.sol";
import "../../libraries/math/IporMath.sol";

library IporLogic {
    function accrueQuasiIbtPrice(IporOracleTypes.IPOR memory ipor, uint256 accrueTimestamp)
        internal
        pure
        returns (uint256)
    {
        return
            accrueQuasiIbtPrice(
                ipor.indexValue,
                ipor.quasiIbtPrice,
                ipor.lastUpdateTimestamp,
                accrueTimestamp
            );
    }

    //@param indexValue indexValue represented in WAD
    //@param quasiIbtPrice quasiIbtPrice represented in WAD, "quasi" prefix indicates that IBT Price doesn't have final value. It is required to divide by number of seconds in year
    //@dev return value represented in WAD
    function accrueQuasiIbtPrice(
        uint256 indexValue,
        uint256 quasiIbtPrice,
        uint256 indexTimestamp,
        uint256 accrueTimestamp
    ) internal pure returns (uint256) {
        require(
            accrueTimestamp >= indexTimestamp,
            IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );
        return quasiIbtPrice + (indexValue * (accrueTimestamp - indexTimestamp));
    }

}
