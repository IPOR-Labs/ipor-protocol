// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Offered rate calculation library
library OfferedRateCalculationLibsGenOne {
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Calculates the offered rate for the pay-fixed side based on the provided spread and risk inputs.
    /// @param iporIndexValue The IPOR index value.
    /// @param baseSpreadPerLeg The base spread per leg.
    /// @param demandSpread The demand spread.
    /// @param payFixedMinCap The pay-fixed minimum cap.
    /// @return offeredRate The calculated offered rate for pay-fixed side.
    function calculatePayFixedOfferedRate(
        uint256 iporIndexValue,
        int256 baseSpreadPerLeg,
        uint256 demandSpread,
        uint256 payFixedMinCap
    ) internal pure returns (uint256 offeredRate) {
        int256 baseOfferedRate = iporIndexValue.toInt256() + baseSpreadPerLeg;

        if (baseOfferedRate > payFixedMinCap.toInt256()) {
            offeredRate = baseOfferedRate.toUint256() + demandSpread;
        } else {
            offeredRate = payFixedMinCap + demandSpread;
        }
    }

    /// @notice Calculates the offered rate for the receive-fixed side based on the provided spread and risk inputs.
    /// @param iporIndexValue The IPOR index value.
    /// @param baseSpreadPerLeg The base spread per leg.
    /// @param demandSpread The demand spread.
    /// @param receiveFixedMaxCap The receive-fixed maximum cap.
    /// @return offeredRate The calculated offered rate for receive-fixed side.
    function calculateReceiveFixedOfferedRate(
        uint256 iporIndexValue,
        int256 baseSpreadPerLeg,
        uint256 demandSpread,
        uint256 receiveFixedMaxCap
    ) internal pure returns (uint256 offeredRate) {
        int256 baseOfferedRate = iporIndexValue.toInt256() + baseSpreadPerLeg;

        int256 temp;
        if (baseOfferedRate < receiveFixedMaxCap.toInt256()) {
            temp = baseOfferedRate - demandSpread.toInt256();
        } else {
            temp = receiveFixedMaxCap.toInt256() - demandSpread.toInt256();
        }
        offeredRate = temp < 0 ? 0 : temp.toUint256();
    }
}
