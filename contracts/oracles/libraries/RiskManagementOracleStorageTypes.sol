// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/// @notice types used in IporRiskManagementOracle's storage
library IporRiskManagementOracleStorageTypes {
    struct RiskIndicatorsStorage {
        /// @notice max notional for pay fixed leg, 1 = 10k
        uint64 maxNotionalPayFixed;
        /// @notice max notional for receive fixed leg, 1 = 10k
        uint64 maxNotionalReceiveFixed;
        /// @notice utilization rate for pay fixed leg, 1 = 0.01%
        uint16 maxUtilizationRatePayFixed;
        /// @notice utilization rate for receive fixed leg, 1 = 0.01%
        uint16 maxUtilizationRateReceiveFixed;
        /// @notice utilization rate for both legs, 1 = 0.01%
        uint16 maxUtilizationRate;
        /// @notice Timestamp of most recent indicators update
        uint32 lastUpdateTimestamp;
    }
}
