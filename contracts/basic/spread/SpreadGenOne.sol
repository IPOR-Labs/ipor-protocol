// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/IIporContractCommonGov.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../interfaces/types/AmmTypes.sol";
import "../../libraries/IporContractValidator.sol";
import "../../security/PauseManager.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../../amm/libraries/types/AmmInternalTypes.sol";
import "../../amm/libraries/IporSwapLogic.sol";
import "../../amm/spread/SpreadStorageLibs.sol";
import "../../amm/spread/CalculateTimeWeightedNotionalLibs.sol";
import "../../basic/interfaces/IAmmStorageGenOne.sol";
import "./DemandSpreadLibsGenOne.sol";
import "./SpreadStorageLibsGenOne.sol";
import "./OfferedRateCalculationLibsGenOne.sol";

/// @dev This contract cannot be used directly, should be used only through Router.
contract SpreadGenOne is IporOwnable, ISpreadGenOne  {

    error UnknownTenor(IporTypes.SwapTenor tenor, string errorCode, string methodName);

    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    address public immutable asset;
    address public immutable iporProtocolRouter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address iporProtocolRouterInput,
        address assetInput,
        SpreadTypesGenOne.TimeWeightedNotionalMemory[] memory timeWeightedNotional
    ) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        asset = assetInput.checkAddress();
        uint256 length = timeWeightedNotional.length;
        for (uint256 i; i < length; ) {
            SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(
                timeWeightedNotional[i].storageId,
                timeWeightedNotional[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    modifier onlyRouter() {
        require(msg.sender == iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    function calculateAndUpdateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external onlyRouter override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixedAndUpdateTimeWeightedNotional(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRate(
        AmmTypes.SwapDirection direction,
        SpreadInputs calldata spreadInputs
    ) external view override returns (uint256) {
        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            return
                OfferedRateCalculationLibsGenOne.calculatePayFixedOfferedRate(
                    spreadInputs.iporIndexValue,
                    spreadInputs.baseSpreadPerLeg,
                    _calculateDemandPayFixed(spreadInputs),
                    spreadInputs.fixedRateCapPerLeg
                );
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            return
                OfferedRateCalculationLibsGenOne.calculateReceiveFixedOfferedRate(
                    spreadInputs.iporIndexValue,
                    spreadInputs.baseSpreadPerLeg,
                    _calculateDemandReceiveFixed(spreadInputs),
                    spreadInputs.fixedRateCapPerLeg
                );
        } else {
            revert IporErrors.UnsupportedDirection(uint256(direction));
        }
    }

    function calculateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixed(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateAndUpdateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external onlyRouter override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixed(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function updateTimeWeightedNotionalOnClose(
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external onlyRouter override {
        // @dev when timestamp is 0, it means that the swap was open in ipor-protocol v1 .
        if (closedSwap.openSwapTimestamp == 0) {
            return;
        }
        uint256 tenorInSeconds = IporSwapLogic.getTenorInSeconds(tenor);
        SpreadStorageLibsGenOne.StorageId storageId = _calculateStorageId(tenor);
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory timeWeightedNotional = SpreadStorageLibsGenOne
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
            AmmInternalTypes.OpenSwapItem memory lastOpenSwap = IAmmStorageGenOne(ammStorageAddress).getLastOpenedSwap(
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

        SpreadStorageLibsGenOne.saveTimeWeightedNotionalForAssetAndTenor(storageId, timeWeightedNotional);
    }

    function getTimeWeightedNotional()
    external
    view
    override
    returns (SpreadTypesGenOne.TimeWeightedNotionalResponse[] memory timeWeightedNotionalResponse)
    {
        (SpreadStorageLibsGenOne.StorageId[] memory storageIds, string[] memory keys) = SpreadStorageLibsGenOne.getAllStorageId();
        uint256 storageIdLength = storageIds.length;
        timeWeightedNotionalResponse = new SpreadTypesGenOne.TimeWeightedNotionalResponse[](storageIdLength);

        for (uint256 i; i != storageIdLength; ) {
            timeWeightedNotionalResponse[i].timeWeightedNotional = SpreadStorageLibsGenOne
                .getTimeWeightedNotionalForAssetAndTenor(storageIds[i]);
            timeWeightedNotionalResponse[i].key = keys[i];
            unchecked {
                ++i;
            }
        }
    }

    function spreadFunctionConfig() external pure override returns (uint256[] memory) {
        return DemandSpreadLibsGenOne.spreadFunctionConfig();
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_001;
    }

    function _calculateDemandPayFixed(SpreadInputs memory spreadInputs) internal view returns (uint256 spreadValue) {
        DemandSpreadLibsGenOne.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibsGenOne.calculatePayFixedSpread(inputData);
    }

    function _calculateDemandPayFixedAndUpdateTimeWeightedNotional(
        SpreadInputs memory spreadInputs
    ) internal returns (uint256 spreadValue) {
        DemandSpreadLibsGenOne.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);
        spreadValue = DemandSpreadLibsGenOne.calculatePayFixedSpread(inputData);

        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibsGenOne
            .getTimeWeightedNotionalForAssetAndTenor(inputData.timeWeightedNotionalStorageId);

        CalculateTimeWeightedNotionalLibsGenOne.updateTimeWeightedNotionalPayFixed(
            weightedNotional,
            inputData.swapNotional,
            _calculateTenorInSeconds(spreadInputs.tenor)
        );
    }

    function _calculateDemandReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) internal view returns (uint256 spreadValue) {
        DemandSpreadLibsGenOne.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibsGenOne.calculateReceiveFixedSpread(inputData);
    }

    function _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional(
        SpreadInputs calldata spreadInputs
    ) internal returns (uint256 spreadValue) {
        DemandSpreadLibsGenOne.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibsGenOne.calculateReceiveFixedSpread(inputData);
        SpreadTypesGenOne.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibsGenOne
            .getTimeWeightedNotionalForAssetAndTenor(inputData.timeWeightedNotionalStorageId);

        CalculateTimeWeightedNotionalLibsGenOne.updateTimeWeightedNotionalReceiveFixed(
            weightedNotional,
            inputData.swapNotional,
            _calculateTenorInSeconds(spreadInputs.tenor)
        );
    }

    function _getSpreadConfigForDemand(
        SpreadInputs memory spreadInputs
    ) internal view returns (DemandSpreadLibsGenOne.SpreadInputData memory inputData) {
        inputData = DemandSpreadLibsGenOne.SpreadInputData({
            totalCollateralPayFixed: spreadInputs.totalCollateralPayFixed,
            totalCollateralReceiveFixed: spreadInputs.totalCollateralReceiveFixed,
            liquidityPoolBalance: spreadInputs.liquidityPoolBalance,
            swapNotional: spreadInputs.swapNotional,
            demandSpreadFactor: spreadInputs.demandSpreadFactor,
            tenorsInSeconds: new uint256[](3),
            timeWeightedNotionalStorageIds: new SpreadStorageLibsGenOne.StorageId[](3),
            timeWeightedNotionalStorageId: _calculateStorageId(spreadInputs.tenor),
            selectedTenorInSeconds: _calculateTenorInSeconds(spreadInputs.tenor)
        });

        inputData.tenorsInSeconds[0] = 28 days;
        inputData.tenorsInSeconds[1] = 60 days;
        inputData.tenorsInSeconds[2] = 90 days;

        inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days;
        inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days;
        inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days;
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
    ) private pure returns (SpreadStorageLibsGenOne.StorageId storageId) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional28Days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional60Days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return SpreadStorageLibsGenOne.StorageId.TimeWeightedNotional90Days;
        }
        revert UnknownTenor({
            tenor: tenor,
            errorCode: AmmErrors.UNSUPPORTED_SWAP_TENOR,
            methodName: "_calculateStorageId"
        });
    }
}
