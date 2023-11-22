// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../libraries/math/IporMath.sol";
import "./SpreadTypesGenOne.sol";
import "./SpreadStorageLibsGenOne.sol";

library CalculateTimeWeightedNotionalLibsGenOne {
    /// @notice calculate amm lp depth
    /// @param liquidityPoolBalance liquidity pool balance
    /// @param totalCollateralPayFixed total collateral pay fixed
    /// @param totalCollateralReceiveFixed total collateral receive fixed
    function calculateLpDepth(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) internal pure returns (uint256 lpDepth) {
        if (totalCollateralPayFixed >= totalCollateralReceiveFixed) {
            lpDepth = liquidityPoolBalance + totalCollateralReceiveFixed - totalCollateralPayFixed;
        } else {
            lpDepth = liquidityPoolBalance + totalCollateralPayFixed - totalCollateralReceiveFixed;
        }
    }

    /// @notice calculate weighted notional
    /// @param timeWeightedNotional weighted notional value
    /// @param timeFromLastUpdate time from last update in seconds
    /// @param tenorInSeconds tenor in seconds
    function calculateTimeWeightedNotional(
        uint256 timeWeightedNotional,
        uint256 timeFromLastUpdate,
        uint256 tenorInSeconds
    ) internal pure returns (uint256) {
        if (timeFromLastUpdate >= tenorInSeconds) {
            return 0;
        }
        uint256 newTimeWeightedNotional = IporMath.divisionWithoutRound(
            timeWeightedNotional * (tenorInSeconds - timeFromLastUpdate),
            tenorInSeconds
        );
        return newTimeWeightedNotional;
    }

    /// @notice Updates the time-weighted notional value for the receive fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param tenorInSeconds Tenor in seconds.
    /// @dev This function is internal and used to update the time-weighted notional value for the receive fixed leg.
    function updateTimeWeightedNotionalReceiveFixed(
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 tenorInSeconds
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalReceiveFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                newSwapNotional,
                0,
                tenorInSeconds
            );
        } else {
            uint256 oldWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                tenorInSeconds
            );
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = newSwapNotional + oldWeightedNotionalReceiveFixed;
        }
        timeWeightedNotional.lastUpdateTimeReceiveFixed = block.timestamp;
        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            timeWeightedNotional.storageId,
            timeWeightedNotional
        );
    }

    /// @notice Updates the time-weighted notional value for the pay fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param tenorInSeconds Tenor in seconds.
    /// @dev This function is internal and used to update the time-weighted notional value for the pay fixed leg.
    function updateTimeWeightedNotionalPayFixed(
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 tenorInSeconds
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalPayFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                newSwapNotional,
                0,
                tenorInSeconds
            );
        } else {
            uint256 oldWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalPayFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                tenorInSeconds
            );
            timeWeightedNotional.timeWeightedNotionalPayFixed = newSwapNotional + oldWeightedNotionalPayFixed;
        }
        timeWeightedNotional.lastUpdateTimePayFixed = block.timestamp;
        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
            timeWeightedNotional.storageId,
            timeWeightedNotional
        );
    }

    /// @notice Calculates the time-weighted notional values for the pay fixed and receive fixed legs.
    /// @param timeWeightedNotionalStorageIds The array of storage IDs representing the time-weighted notional storage locations.
    /// @param tenorsInSeconds The array of maturities corresponding to each storage ID.
    /// @param selectedTenorInSeconds The tenor in seconds used to calculate the time-weighted notional values.
    /// @return timeWeightedNotionalPayFixed The aggregated time-weighted notional value for the pay fixed leg.
    /// @return timeWeightedNotionalReceiveFixed The aggregated time-weighted notional value for the receive fixed leg.
    /// @dev This function is internal and used to calculate the aggregated time-weighted notional values for multiple storage IDs and maturities.
    function getTimeWeightedNotional(
        SpreadStorageLibsGenOne.StorageId[] memory timeWeightedNotionalStorageIds,
        uint256[] memory tenorsInSeconds,
        uint256 selectedTenorInSeconds
    ) internal view returns (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) {
        uint256 length = timeWeightedNotionalStorageIds.length;

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory timeWeightedNotional;
        uint256 timeWeightedNotionalPayFixedIteration;
        uint256 timeWeightedNotionalReceiveFixedIteration;

        for (uint256 i; i != length; ) {
            timeWeightedNotional = SpreadStorageLibsGenOne.getTimeWeightedNotionalForAssetAndTenor(
                timeWeightedNotionalStorageIds[i]
            );
            timeWeightedNotionalPayFixedIteration = _isTimeWeightedNotionalRecalculationRequired(
                timeWeightedNotional.lastUpdateTimePayFixed,
                tenorsInSeconds[i],
                selectedTenorInSeconds
            )
                ? calculateTimeWeightedNotional(
                    timeWeightedNotional.timeWeightedNotionalPayFixed,
                    block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                    tenorsInSeconds[i]
                )
                : timeWeightedNotional.timeWeightedNotionalPayFixed;
            timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixed + timeWeightedNotionalPayFixedIteration;

            timeWeightedNotionalReceiveFixedIteration = _isTimeWeightedNotionalRecalculationRequired(
                timeWeightedNotional.lastUpdateTimeReceiveFixed,
                tenorsInSeconds[i],
                selectedTenorInSeconds
            )
                ? calculateTimeWeightedNotional(
                    timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                    block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                    tenorsInSeconds[i]
                )
                : timeWeightedNotional.timeWeightedNotionalReceiveFixed;
            timeWeightedNotionalReceiveFixed =
                timeWeightedNotionalReceiveFixedIteration +
                timeWeightedNotionalReceiveFixed;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Determines if the time-weighted notional should be recalculated based on the last update time and tenors.
    /// @param lastUpdateTime The last time the notional was updated.
    /// @param iterationTenorInSeconds The tenor duration in seconds.
    /// @param selectedTenorInSeconds The duration in seconds for which the spread should be calculated for a given tenor.
    /// @dev This function is internal and used to decide if a recalculation of the time-weighted notional is necessary.
    function _isTimeWeightedNotionalRecalculationRequired(
        uint256 lastUpdateTime,
        uint256 iterationTenorInSeconds,
        uint256 selectedTenorInSeconds
    ) internal view returns (bool) {
        return iterationTenorInSeconds + lastUpdateTime < block.timestamp + selectedTenorInSeconds;
    }
}
