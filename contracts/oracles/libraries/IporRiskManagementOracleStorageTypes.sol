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

    struct BaseSpreadsStorage {
        /// @notice Timestamp of most recent indicators update
        uint32 lastUpdateTimestamp;
        /// @notice spread for 28 days pay fixed swap
        int24 spread28dPayFixed;
        /// @notice spread for 28 days receive fixed swap
        int24 spread28dReceiveFixed;
        /// @notice spread for 60 days pay fixed swap
        int24 spread60dPayFixed;
        /// @notice spread for 60 days receive fixed swap
        int24 spread60dReceiveFixed;
        /// @notice spread for 90 days pay fixed swap
        int24 spread90dPayFixed;
        /// @notice spread for 90 days receive fixed swap
        int24 spread90dReceiveFixed;
        /// @notice fixed rate cap for 28 days pay fixed swap
        uint16 fixedRateCap28dPayFixed;
        /// @notice fixed rate cap for 28 days receive fixed swap
        uint16 fixedRateCap28dReceiveFixed;
        /// @notice fixed rate cap for 60 days pay fixed swap
        uint16 fixedRateCap60dPayFixed;
        /// @notice fixed rate cap for 60 days receive fixed swap
        uint16 fixedRateCap60dReceiveFixed;
        /// @notice fixed rate cap for 90 days pay fixed swap
        uint16 fixedRateCap90dPayFixed;
        /// @notice fixed rate cap for 90 days receive fixed swap
        uint16 fixedRateCap90dReceiveFixed;
    }
}
