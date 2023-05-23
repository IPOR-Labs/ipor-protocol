// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

library ItfAmmTreasuryTypes {
    struct ItfUtilization {
        uint256 maxLpUtilizationRate;
        uint256 maxLpUtilizationPerLegRate;
    }
    struct ItfFees {
        uint256 openingFeeRate;
        uint256 openingFeeForTreasuryPortionRate;
        uint256 iporPublicationFee;
    }
    struct ItfLeverage {
        uint256 maxLeverage;
        uint256 minLeverage;
    }
}
