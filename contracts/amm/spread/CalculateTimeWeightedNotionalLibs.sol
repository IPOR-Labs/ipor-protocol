// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./SpreadTypes.sol";
import "./SpreadStorageLibs.sol";
import "contracts/libraries/math/IporMath.sol";

library CalculateTimeWeightedNotionalLibs {
    /// @notice calculate amm lp depth
    /// @param lpBalance lp balance
    /// @param totalCollateralPayFixed total collateral pay fixed
    /// @param totalCollateralReceiveFixed total collateral receive fixed
    function calculateLpDepth(
        uint256 lpBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) internal view returns (uint256 lpDepth) {
        if (totalCollateralPayFixed >= totalCollateralReceiveFixed) {
            lpDepth = lpBalance + totalCollateralReceiveFixed - totalCollateralPayFixed;
        } else {
            lpDepth = lpBalance + totalCollateralPayFixed - totalCollateralReceiveFixed;
        }
    }

    /// @notice calculate weighted notional
    /// @param timeWeightedNotional weighted notional value
    /// @param timeFromLastUpdate time from last update in seconds
    /// @param maturity maturity in seconds
    function calculateTimeWeightedNotional(
        uint256 timeWeightedNotional,
        uint256 timeFromLastUpdate,
        uint256 maturity
    ) internal view returns (uint256) {
        if (timeFromLastUpdate >= maturity) {
            return 0;
        }
        uint256 newTimeWeightedNotional = IporMath.divisionWithoutRound(
            timeWeightedNotional * (maturity - timeFromLastUpdate),
            maturity
        );
        return newTimeWeightedNotional;
    }

    /// @notice Updates the time-weighted notional value for the receive fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param maturity The maturity timestamp.
    /// @dev This function is internal and used to update the time-weighted notional value for the receive fixed leg.
    function updateTimeWeightedNotionalReceiveFixed(
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 maturity
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalReceiveFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(newSwapNotional, 0, maturity);
        } else {
            uint256 oldWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                maturity
            );
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = newSwapNotional + oldWeightedNotionalReceiveFixed;
        }
        timeWeightedNotional.lastUpdateTimeReceiveFixed = block.timestamp;
        SpreadStorageLibs.saveTimeWeightedNotional(timeWeightedNotional.storageId, timeWeightedNotional);
    }

    /// @notice Updates the time-weighted notional value for the pay fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param maturity The maturity timestamp.
    /// @dev This function is internal and used to update the time-weighted notional value for the pay fixed leg.
    function updateTimeWeightedNotionalPayFixed(
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 maturity
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalPayFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalPayFixed = calculateTimeWeightedNotional(newSwapNotional, 0, maturity);
        } else {
            uint256 oldWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalPayFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                maturity
            );
            timeWeightedNotional.timeWeightedNotionalPayFixed = newSwapNotional + oldWeightedNotionalPayFixed;
        }
        timeWeightedNotional.lastUpdateTimePayFixed = block.timestamp;
        SpreadStorageLibs.saveTimeWeightedNotional(timeWeightedNotional.storageId, timeWeightedNotional);
    }

    /// @notice Calculates the time-weighted notional values for the pay fixed and receive fixed legs.
    /// @param storageIds The array of storage IDs representing the time-weighted notional storage locations.
    /// @param maturities The array of maturities corresponding to each storage ID.
    /// @return timeWeightedNotionalPayFixed The aggregated time-weighted notional value for the pay fixed leg.
    /// @return timeWeightedNotionalReceiveFixed The aggregated time-weighted notional value for the receive fixed leg.
    /// @dev This function is internal and used to calculate the aggregated time-weighted notional values for multiple storage IDs and maturities.
    function getTimeWeightedNotional(SpreadStorageLibs.StorageId[] memory storageIds, uint256[] memory maturities)
        internal
        returns (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed)
    {
        uint256 length = storageIds.length;
        for (uint256 i; i != length; ) {
            SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
                storageIds[i]
            );
            uint256 timeWeightedNotionalPayFixedTemp = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalPayFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                maturities[i]
            );
            timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixed + timeWeightedNotionalPayFixedTemp;

            uint256 timeWeightedNotionalReceiveFixedTemp = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                maturities[i]
            );
            timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedTemp + timeWeightedNotionalReceiveFixed;
            unchecked {
                ++i;
            }
        }
    }
}