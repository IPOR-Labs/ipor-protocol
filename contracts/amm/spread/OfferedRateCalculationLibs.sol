// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library OfferedRateCalculationLibs {
    using SafeCast for uint256;
    using SafeCast for int256;

    function calculatePayFixedOfferedRate(
        uint256 indexValue,
        int256 baseSpread,
        uint256 demandSpread,
        uint256 cap
    ) internal pure returns (uint256 offeredRate) {
        int256 baseOfferedRate = indexValue.toInt256() + baseSpread;

        if (baseOfferedRate > cap.toInt256()) {
            offeredRate = baseOfferedRate.toUint256() + demandSpread;
        } else {
            offeredRate = cap + demandSpread;
        }
    }

    function calculateReceiveFixedOfferedRate(
        uint256 indexValue,
        int256 baseSpread,
        uint256 demandSpread,
        uint256 cap
    ) internal pure returns (uint256 offeredRate) {
        int256 baseOfferedRate = indexValue.toInt256() + baseSpread;

        int256 temp;
        if (baseOfferedRate < cap.toInt256()) {
            temp = baseOfferedRate - demandSpread.toInt256();
        } else {
            temp = cap.toInt256() - demandSpread.toInt256();
        }
        offeredRate = temp < 0 ? 0 : temp.toUint256();
    }
}
