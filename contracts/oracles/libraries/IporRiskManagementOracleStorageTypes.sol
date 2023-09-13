// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @notice types used in IporRiskManagementOracle's storage
library IporRiskManagementOracleStorageTypes {
    struct RiskIndicatorsStorage {
        /// @notice max notional for pay fixed leg, value is without decimals, is a multiplication of 10_000, example: 1 = 10k
        uint64 maxNotionalPayFixed;
        /// @notice max notional for receive fixed leg, value is without decimals, is a multiplication of 10_000, example: 1 = 10k
        uint64 maxNotionalReceiveFixed;
        /// @notice collateral ratio for pay fixed leg, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint16 maxCollateralRatioPayFixed;
        /// @notice collateral ratio for receive fixed leg, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint16 maxCollateralRatioReceiveFixed;
        /// @notice collateral ratio for both legs, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint16 maxCollateralRatio;
        /// @notice Timestamp of most recent indicators update
        uint32 lastUpdateTimestamp;
        // @notice demand spread factor, value represents without decimals, used to calculate demand spread
        uint16 demandSpreadFactor28;
        uint16 demandSpreadFactor60;
        uint16 demandSpreadFactor90;
    }


    struct BaseSpreadsAndFixedRateCapsStorage {
        /// @notice Timestamp of most recent indicators update
        uint256 lastUpdateTimestamp;
        /// @notice spread for 28 days pay fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread28dPayFixed;
        /// @notice spread for 28 days receive fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread28dReceiveFixed;
        /// @notice spread for 60 days pay fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread60dPayFixed;
        /// @notice spread for 60 days receive fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread60dReceiveFixed;
        /// @notice spread for 90 days pay fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread90dPayFixed;
        /// @notice spread for 90 days receive fixed swap, value represents percentage with 4 decimals, example: 1 = 0.0001%, 10000 = 1%, 100 = 0.01%
        int256 spread90dReceiveFixed;
        /// @notice fixed rate cap for 28 days pay fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap28dPayFixed;
        /// @notice fixed rate cap for 28 days receive fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap28dReceiveFixed;
        /// @notice fixed rate cap for 60 days pay fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap60dPayFixed;
        /// @notice fixed rate cap for 60 days receive fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap60dReceiveFixed;
        /// @notice fixed rate cap for 90 days pay fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap90dPayFixed;
        /// @notice fixed rate cap for 90 days receive fixed swap, value represents percentage with 2 decimals, example: 100 = 1%, 1 = 0.01%, 10000 = 100%
        uint256 fixedRateCap90dReceiveFixed;
    }
}
