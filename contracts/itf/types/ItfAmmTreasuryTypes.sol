// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

library ItfAmmTreasuryTypes {
    struct ItfCollateralRatio {
        uint256 maxLpCollateralRatio;
        uint256 maxLpCollateralRatioPerLegRate;
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
