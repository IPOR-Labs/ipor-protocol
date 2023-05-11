// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Structs used in IporRiskManagementOracle smart contract
library IporRiskManagementOracleTypes {
    //@notice Risk Indicators Structure for a given asset
    struct RiskIndicators {
        /// @notice maximum notional value for pay fixed leg, 1 = 10k
        uint256 maxNotionalPayFixed;
        /// @notice maximum notional value for receive fixed leg, 1 = 10k
        uint256 maxNotionalReceiveFixed;
        /// @notice maximum utilization rate for pay fixed leg, 1 = 0.01%
        uint256 maxUtilizationRatePayFixed;
        /// @notice maximum utilization rate for receive fixed leg, 1 = 0.01%
        uint256 maxUtilizationRateReceiveFixed;
        /// @notice maximum utilization rate for both legs, 1 = 0.01%
        uint256 maxUtilizationRate;
    }

    //@notice Base Spread Structure for a given asset, both legs and all maturities
    struct BaseSpreads {
        /// @notice spread for 28 days pay fixed swap
        int256 spread28dPayFixed;
        /// @notice spread for 28 days receive fixed swap
        int256 spread28dReceiveFixed;
        /// @notice spread for 60 days pay fixed swap
        int256 spread60dPayFixed;
        /// @notice spread for 60 days receive fixed swap
        int256 spread60dReceiveFixed;
        /// @notice spread for 90 days pay fixed swap
        int256 spread90dPayFixed;
        /// @notice spread for 90 days receive fixed swap
        int256 spread90dReceiveFixed;
    }
}
