// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/amm/libraries/types/AmmInternalTypes.sol";
import "contracts/interfaces/types/AmmTypes.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "contracts/libraries/errors/AmmErrors.sol";
import "contracts/amm/libraries/IporSwapLogic.sol";
import "./ISpreadCloseSwapService.sol";
import "./SpreadStorageLibs.sol";
import "./CalculateTimeWeightedNotionalLibs.sol";

contract SpreadCloseSwapService is ISpreadCloseSwapService {
    using SafeCast for uint256;

    address internal immutable _DAI;
    address internal immutable _USDC;
    address internal immutable _USDT;

    constructor(
        address dai,
        address usdc,
        address usdt
    ) {
        require(dai != address(0), string.concat(IporErrors.WRONG_ADDRESS, " DAI asset address cannot be 0"));
        require(usdc != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDC asset address cannot be 0"));
        require(usdt != address(0), string.concat(IporErrors.WRONG_ADDRESS, " USDT asset address cannot be 0"));

        _DAI = dai;
        _USDC = usdc;
        _USDT = usdt;
    }

    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external {
        // @dev when timestamp is 0, it means that the swap was open in ipor-protocole v1 .
        if (closedSwap.openSwapTimestamp == 0) {
            return;
        }
        uint256 tenorInSeconds = IporSwapLogic.getTenorInSeconds(tenor);
        SpreadStorageLibs.StorageId storageId = _getStorageId(asset, tenor);
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional = SpreadStorageLibs.getTimeWeightedNotional(
            storageId
        );

        uint256 timeWeightedNotionalAmount = direction == 0
            ? timeWeightedNotional.timeWeightedNotionalPayFixed
            : timeWeightedNotional.timeWeightedNotionalReceiveFixed;
        uint256 timeOfLastUpdate = direction == 0
            ? timeWeightedNotional.lastUpdateTimePayFixed
            : timeWeightedNotional.lastUpdateTimeReceiveFixed;

        uint256 timeWeightedNotionalToRemove = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            swapNotional,
            // @dev timeOfLastUpdate should be greater than closedSwap.openSwapTimestamp
            timeOfLastUpdate - closedSwap.openSwapTimestamp,
            tenorInSeconds
        );

        uint256 actualTimeWeightedNotionalToSave;
        if (timeWeightedNotionalAmount > timeWeightedNotionalToRemove) {
            actualTimeWeightedNotionalToSave = timeWeightedNotionalAmount - timeWeightedNotionalToRemove;
        }

        if (closedSwap.nextSwapId == 0) {
            AmmInternalTypes.OpenSwapItem memory lastOpenSwap = IAmmStorage(ammStorageAddress).getLastOpenedSwap(
                tenor,
                direction
            );
            uint256 swapTimePast = block.timestamp - uint256(lastOpenSwap.openSwapTimestamp);
            if (tenorInSeconds <= swapTimePast) {
                actualTimeWeightedNotionalToSave = 0;
                swapTimePast = 0;
            }
            if (direction == 0) {
                timeWeightedNotional.lastUpdateTimePayFixed = lastOpenSwap.openSwapTimestamp;
                timeWeightedNotional.timeWeightedNotionalPayFixed =
                    (actualTimeWeightedNotionalToSave * tenorInSeconds) /
                    (tenorInSeconds - swapTimePast);
            } else {
                timeWeightedNotional.lastUpdateTimeReceiveFixed = lastOpenSwap.openSwapTimestamp;
                timeWeightedNotional.timeWeightedNotionalReceiveFixed =
                    (actualTimeWeightedNotionalToSave * tenorInSeconds) /
                    (tenorInSeconds - swapTimePast);
            }
        } else {
            if (direction == 0) {
                timeWeightedNotional.timeWeightedNotionalPayFixed = actualTimeWeightedNotionalToSave;
            } else {
                timeWeightedNotional.timeWeightedNotionalReceiveFixed = actualTimeWeightedNotionalToSave;
            }
        }

        SpreadStorageLibs.saveTimeWeightedNotional(storageId, timeWeightedNotional);
    }

    function _getStorageId(address asset, IporTypes.SwapTenor tenor)
        internal
        returns (SpreadStorageLibs.StorageId storageId)
    {
        if (asset == _DAI) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;
            }
        } else if (asset == _USDC) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc;
            }
        } else if (asset == _USDT) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt;
            }
        } else {
            revert(IporErrors.WRONG_ADDRESS);
        }
        if (uint256(storageId) == 0) {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }
}
