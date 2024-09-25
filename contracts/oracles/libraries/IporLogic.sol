// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import "../../interfaces/types/IporOracleTypes.sol";
import "../../libraries/errors/IporOracleErrors.sol";

/// @title Ipor Index logic library
library IporLogic {
    /// @notice Acrrues the quasi IBT price
    /// @param ipor IPOR struct
    /// @param accrueTimestamp Accrue timestamp
    /// @return Accrued quasi IBT price
    function accrueQuasiIbtPrice(
        IporOracleTypes.IPOR memory ipor,
        uint256 accrueTimestamp
    ) internal pure returns (uint256) {
        require(
            accrueTimestamp >= ipor.lastUpdateTimestamp,
            IporOracleErrors.INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP
        );
        return ipor.quasiIbtPrice + (ipor.indexValue * (accrueTimestamp - ipor.lastUpdateTimestamp));
    }
}
