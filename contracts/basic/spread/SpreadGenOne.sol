// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DemandSpreadLibsGenOne.sol";
import "./SpreadStorageLibsGenOne.sol";
import "./OfferedRateCalculationLibsGenOne.sol";
import "../../interfaces/IIporContractCommonGov.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../../interfaces/types/IporTypes.sol";
import "../../security/IporOwnableUpgradeable.sol";
import "../../security/PauseManager.sol";
import "../../libraries/IporContractValidator.sol";

/// @dev This contract cannot be used directly, should be used only through SpreadRouter.
contract SpreadGenOne is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IProxyImplementation,
    IIporContractCommonGov
{
    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
        IporTypes.SwapTenor tenor;
    }

    error UnknownTenor(IporTypes.SwapTenor tenor, string errorCode, string methodName);

    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    address public immutable asset;
    address public immutable iporProtocolRouter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporProtocolRouterInput, address assetInput) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        asset = assetInput.checkAddress();
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_GUARDIAN);
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == iporProtocolRouter, IporErrors.CALLER_NOT_IPOR_PROTOCOL_ROUTER);
        _;
    }

    function calculateAndUpdateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external onlyRouter returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixedAndUpdateTimeWeightedNotional(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRatePayFixed(
        SpreadInputs calldata spreadInputs
    ) external view returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixed(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateAndUpdateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external onlyRouter returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateImbalanceReceiveFixedAndUpdateTimeWeightedNotional(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRateReceiveFixed(
        SpreadInputs calldata spreadInputs
    ) external view returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibsGenOne.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixed(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function spreadFunctionConfig() external pure returns (uint256[] memory) {
        return DemandSpreadLibsGenOne.spreadFunctionConfig();
    }

    /// @notice Gets the implementation address of a Spread Router.
    function getImplementation() external view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function getVersion() external pure virtual returns (uint256) {
        return 2_000;
    }

    function pause() external onlyPauseGuardian {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isPauseGuardian(address account) external view returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    function addPauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    function removePauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.removePauseGuardians(guardians);
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

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
