// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IporTypes} from "../../interfaces/types/IporTypes.sol";
import {AmmTypes} from "../../interfaces/types/AmmTypes.sol";
import {IporContractValidator} from "../../libraries/IporContractValidator.sol";
import {IporOwnable} from "../../security/IporOwnable.sol";
import {AmmInternalTypes} from "../../amm/libraries/types/AmmInternalTypes.sol";
import {SpreadStorageLibs} from "../../amm/spread/SpreadStorageLibs.sol";
import {CalculateTimeWeightedNotionalLibs} from "../../amm/spread/CalculateTimeWeightedNotionalLibs.sol";
import {IAmmStorageBaseV1} from "../../base/interfaces/IAmmStorageBaseV1.sol";
import {AmmEventsBaseV1} from "../../base/events/AmmEventsBaseV1.sol";
import {ISpreadBaseV1} from "../interfaces/ISpreadBaseV1.sol";
import {SpreadInputData} from "../interfaces/DemandSpreadTypesBaseV1.sol";
import {SwapLogicBaseV1} from "../amm/libraries/SwapLogicBaseV1.sol";
import {SpreadStorageLibsBaseV1} from "./SpreadStorageLibsBaseV1.sol";
import {OfferedRateCalculationLibsBaseV1} from "./OfferedRateCalculationLibsBaseV1.sol";
import {SpreadTypesBaseV1} from "../types/SpreadTypesBaseV1.sol";
import {CalculateTimeWeightedNotionalLibsBaseV1} from "./CalculateTimeWeightedNotionalLibsBaseV1.sol";
import {IporErrors} from "../../libraries/errors/IporErrors.sol";
import {AmmErrors} from "../../libraries/errors/AmmErrors.sol";

// @dev This contract should calculate the spread for one asset and for all tenors.
abstract contract SpreadBaseV2 is IporOwnable, ISpreadBaseV1 {
    error UnknownTenor(IporTypes.SwapTenor tenor, string errorCode, string methodName);
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    address public immutable asset;
    address public immutable iporProtocolRouter;

    modifier onlyRouter() {
        require(msg.sender == iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address iporProtocolRouterInput,
        address assetInput,
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[] memory timeWeightedNotional
    ) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        asset = assetInput.checkAddress();
        uint256 length = timeWeightedNotional.length;
        for (uint256 i; i < length; ) {
            SpreadStorageLibsBaseV1.saveTimeWeightedNotionalForAssetAndTenor(
                timeWeightedNotional[i].storageId,
                timeWeightedNotional[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_002;
    }

    function spreadFunctionConfig() external pure override virtual returns (uint256[] memory);

    function getTimeWeightedNotional()
        external
        view
        override
        returns (SpreadTypesBaseV1.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse)
    {
        (SpreadStorageLibsBaseV1.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibsBaseV1
            .getAllStorageId();
        uint256 storageIdLength = storageIds.length;
        timeWeightedNotionalResponse = new SpreadTypesBaseV1.TimeWeightedNotionalResponse[](storageIdLength);

        for (uint256 i; i != storageIdLength; ) {
            timeWeightedNotionalResponse[i].timeWeightedNotional = SpreadStorageLibsBaseV1
                .getTimeWeightedNotionalForAssetAndTenor(storageIds[i]);
            timeWeightedNotionalResponse[i].key = keys[i];
            unchecked {
                ++i;
            }
        }
    }

    function calculateOfferedRate(
        AmmTypes.SwapDirection direction,
        SpreadInputs calldata spreadInputs
    ) external view override returns (uint256) {
        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            return
                OfferedRateCalculationLibsBaseV1.calculatePayFixedOfferedRate(
                    spreadInputs.iporIndexValue,
                    spreadInputs.baseSpreadPerLeg,
                    _calculateDemandPayFixed(spreadInputs),
                    spreadInputs.fixedRateCapPerLeg
                );
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            return
                OfferedRateCalculationLibsBaseV1.calculateReceiveFixedOfferedRate(
                    spreadInputs.iporIndexValue,
                    spreadInputs.baseSpreadPerLeg,
                    _calculateDemandReceiveFixed(spreadInputs),
                    spreadInputs.fixedRateCapPerLeg
                );
        } else {
            revert IporErrors.UnsupportedDirection(AmmErrors.UNSUPPORTED_DIRECTION, uint256(direction));
        }
    }

    function calculateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsBaseV1.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixed(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsBaseV1.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixed(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateAndUpdateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external override onlyRouter returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsBaseV1.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixedAndUpdateTimeWeightedNotional(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateAndUpdateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external override onlyRouter returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsBaseV1.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function updateTimeWeightedNotionalOnClose(
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external override onlyRouter {
        // @dev when timestamp is 0, it means that the swap was open in ipor-protocol v1 .
        if (closedSwap.openSwapTimestamp == 0) {
            return;
        }
        uint256 tenorInSeconds = SwapLogicBaseV1.getTenorInSeconds(tenor);
        SpreadStorageLibsBaseV1.StorageId storageId = _calculateStorageId(tenor);
        SpreadTypesBaseV1.TimeWeightedNotionalMemory memory timeWeightedNotional = SpreadStorageLibsBaseV1
            .getTimeWeightedNotionalForAssetAndTenor(storageId);

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
            AmmInternalTypes.OpenSwapItem memory lastOpenSwap = IAmmStorageBaseV1(ammStorageAddress).getLastOpenedSwap(
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

        SpreadStorageLibsBaseV1.saveTimeWeightedNotionalForAssetAndTenor(storageId, timeWeightedNotional);
    }

    function updateTimeWeightedNotional(
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[] calldata timeWeightedNotionalMemories
    ) external override onlyOwner {
        uint256 length = timeWeightedNotionalMemories.length;
        for (uint256 i; i < length; ) {
            SpreadStorageLibsBaseV1.checkTimeWeightedNotional(timeWeightedNotionalMemories[i].storageId);
            SpreadStorageLibsBaseV1.saveTimeWeightedNotionalForAssetAndTenor(
                timeWeightedNotionalMemories[i].storageId,
                timeWeightedNotionalMemories[i]
            );

            emit AmmEventsBaseV1.SpreadTimeWeightedNotionalChanged({
                timeWeightedNotionalPayFixed: timeWeightedNotionalMemories[i].timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: timeWeightedNotionalMemories[i].lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalMemories[i].timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: timeWeightedNotionalMemories[i].lastUpdateTimeReceiveFixed,
                storageId: uint256(timeWeightedNotionalMemories[i].storageId)
            });

            unchecked {
                ++i;
            }
        }
    }

    function _calculatePayFixedSpread(SpreadInputData memory inputData) internal virtual view returns (uint256 spreadValue);

    function _calculateDemandPayFixed(SpreadInputs memory spreadInputs) internal view returns (uint256 spreadValue) {
        SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = _calculatePayFixedSpread(inputData);
    }

    function _calculateDemandPayFixedAndUpdateTimeWeightedNotional(
        SpreadInputs memory spreadInputs
    ) internal returns (uint256 spreadValue) {
        SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);
        spreadValue = _calculatePayFixedSpread(inputData);

        SpreadTypesBaseV1.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibsBaseV1
            .getTimeWeightedNotionalForAssetAndTenor(inputData.timeWeightedNotionalStorageId);

        CalculateTimeWeightedNotionalLibsBaseV1.updateTimeWeightedNotionalPayFixed(
            weightedNotional,
            inputData.swapNotional,
            _calculateTenorInSeconds(spreadInputs.tenor)
        );
    }

    function _calculateDemandReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) internal view returns (uint256 spreadValue) {
        SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = _calculateReceiveFixedSpread(inputData);
    }

    function _calculateReceiveFixedSpread(SpreadInputData memory inputData) internal virtual view returns (uint256 spreadValue);

    function _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional(
        SpreadInputs calldata spreadInputs
    ) internal returns (uint256 spreadValue) {
        SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = _calculateReceiveFixedSpread(inputData);
        SpreadTypesBaseV1.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibsBaseV1
            .getTimeWeightedNotionalForAssetAndTenor(inputData.timeWeightedNotionalStorageId);

        CalculateTimeWeightedNotionalLibsBaseV1.updateTimeWeightedNotionalReceiveFixed(
            weightedNotional,
            inputData.swapNotional,
            _calculateTenorInSeconds(spreadInputs.tenor)
        );
    }

    function _getSpreadConfigForDemand(
        SpreadInputs memory spreadInputs
    ) internal pure returns (SpreadInputData memory inputData) {
        inputData = SpreadInputData({
            totalCollateralPayFixed: spreadInputs.totalCollateralPayFixed,
            totalCollateralReceiveFixed: spreadInputs.totalCollateralReceiveFixed,
            liquidityPoolBalance: spreadInputs.liquidityPoolBalance,
            swapNotional: spreadInputs.swapNotional,
            demandSpreadFactor: spreadInputs.demandSpreadFactor,
            tenorsInSeconds: new uint256[](3),
            timeWeightedNotionalStorageIds: new SpreadStorageLibsBaseV1.StorageId[](3),
            timeWeightedNotionalStorageId: _calculateStorageId(spreadInputs.tenor),
            selectedTenorInSeconds: _calculateTenorInSeconds(spreadInputs.tenor)
        });

        inputData.tenorsInSeconds[0] = 28 days;
        inputData.tenorsInSeconds[1] = 60 days;
        inputData.tenorsInSeconds[2] = 90 days;

        inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional28Days;
        inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional60Days;
        inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional90Days;
        return inputData;
    }

    function _calculateTenorInSeconds(IporTypes.SwapTenor tenor) private pure returns (uint256 tenorInSeconds) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return 28 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return 60 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return 90 days;
        }
        revert UnknownTenor({
            tenor: tenor,
            errorCode: AmmErrors.UNSUPPORTED_SWAP_TENOR,
            methodName: "_calculateTenorInSeconds"
        });
    }

    function _calculateStorageId(
        IporTypes.SwapTenor tenor
    ) private pure returns (SpreadStorageLibsBaseV1.StorageId storageId) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional28Days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional60Days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional90Days;
        }
        revert UnknownTenor({
            tenor: tenor,
            errorCode: AmmErrors.UNSUPPORTED_SWAP_TENOR,
            methodName: "_calculateStorageId"
        });
    }
}
