// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./SpreadStorageLibs.sol";
import "./CalculateTimeWeightedNotionalLibs.sol";
import "contracts/libraries/errors/AmmErrors.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "./ISpreadCloseSwapAction.sol";
import "contracts/amm/libraries/types/AmmInternalTypes.sol";
import "contracts/interfaces/types/AmmTypes.sol";
import "contracts/interfaces/IAmmStorage.sol";

contract SpreadCloseSwapAction is ISpreadCloseSwapAction {
    using SafeCast for uint256;

    address internal immutable _DAI;
    address internal immutable _USDC;
    address internal immutable _USDT;

    constructor(
        address dai,
        address usdc,
        address usdt
    ) {
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI"));
        require(usdc != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC"));
        require(usdt != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT"));
        _DAI = dai;
        _USDC = usdc;
        _USDT = usdt;
    }

    function weightedNotionalUpdateOnClose(
        address asset,
        uint256 direction,
        AmmTypes.SwapDuration duration,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external {
        // @dev when timestamp is 0, it means that the swap was open in ipor-protocole v1 .
        if (closedSwap.openSwapTimestamp == 0) {
            return;
        }
        uint256 maturity = _getMaturity(duration);
        SpreadStorageLibs.StorageId storageId = _getStorageId(asset, maturity);
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional = SpreadStorageLibs.getWeightedNotional(
            storageId
        );

        uint256 timeWeightedNotionalAmount = direction == 0
            ? timeWeightedNotional.timeWeightedNotionalPayFixed
            : timeWeightedNotional.timeWeightedNotionalReceiveFixed;
        uint256 timeOfLastUpdate = direction == 0
            ? timeWeightedNotional.lastUpdateTimePayFixed
            : timeWeightedNotional.lastUpdateTimeReceiveFixed;

        uint256 timeWaitedNotionalToRemove = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            swapNotional,
            // @dev timeOfLastUpdate should be greater than closedSwap.openSwapTimestamp
            timeOfLastUpdate - closedSwap.openSwapTimestamp,
            maturity
        );

        uint256 actualTimeWaitedNotionalToSave;
        if (timeWeightedNotionalAmount > timeWaitedNotionalToRemove) {
            actualTimeWaitedNotionalToSave = timeWeightedNotionalAmount - timeWaitedNotionalToRemove;
        }

        if (closedSwap.nextSwapId == 0) {
            AmmInternalTypes.OpenSwapItem memory lastOpenSwap = IAmmStorage(ammStorageAddress).getLastOpenedSwap(
                duration,
                direction
            );
            uint256 swapTimePast = block.timestamp - uint256(lastOpenSwap.openSwapTimestamp);
            if (maturity <= swapTimePast) {
                actualTimeWaitedNotionalToSave = 0;
                swapTimePast = 0;
            }
            if (direction == 0) {
                timeWeightedNotional.lastUpdateTimePayFixed = lastOpenSwap.openSwapTimestamp;
                timeWeightedNotional.timeWeightedNotionalPayFixed = (actualTimeWaitedNotionalToSave * maturity) / (maturity - swapTimePast);
            } else {
                timeWeightedNotional.lastUpdateTimeReceiveFixed = lastOpenSwap.openSwapTimestamp;
                timeWeightedNotional.timeWeightedNotionalReceiveFixed =  (actualTimeWaitedNotionalToSave * maturity) / (maturity - swapTimePast);
            }
        } else {
            if (direction == 0) {
                timeWeightedNotional.timeWeightedNotionalPayFixed = actualTimeWaitedNotionalToSave;
            } else {
                timeWeightedNotional.timeWeightedNotionalReceiveFixed = actualTimeWaitedNotionalToSave;
            }
        }

        SpreadStorageLibs.saveTimeWeightedNotional(storageId, timeWeightedNotional);
    }

    function _getStorageId(address asset, uint256 maturity) internal returns (SpreadStorageLibs.StorageId storageId) {
        if (asset == _DAI) {
            if (maturity == 28 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
            } else if (maturity == 60 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            } else if (maturity == 90 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;
            }
        } else if (asset == _USDC) {
            if (maturity == 28 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc;
            } else if (maturity == 60 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            } else if (maturity == 90 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc;
            }
        } else if (asset == _USDT) {
            if (maturity == 28 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt;
            } else if (maturity == 60 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            } else if (maturity == 90 days) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt;
            }
        } else {
            revert(string.concat(IporErrors.WRONG_ADDRESS, " asset"));
        }
        if (uint256(storageId) == 0) {
            revert(string.concat(AmmErrors.WRONG_MATURITY, " maturity"));
        }
    }

    function _getMaturity(AmmTypes.SwapDuration duration) private pure returns (uint256) {
        if (duration == AmmTypes.SwapDuration.DAYS_28) {
            return 28 days;
        } else if (duration == AmmTypes.SwapDuration.DAYS_60) {
            return 60 days;
        } else if (duration == AmmTypes.SwapDuration.DAYS_90) {
            return 90 days;
        }
        revert(string.concat(AmmErrors.WRONG_MATURITY, " maturity"));
    }
}
