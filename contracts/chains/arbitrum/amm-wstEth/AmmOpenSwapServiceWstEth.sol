// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../interfaces/IAmmOpenSwapServiceWstEth.sol";
import "../../../base/amm/services/AmmOpenSwapServiceBaseV1.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
contract AmmOpenSwapServiceWstEth is AmmOpenSwapServiceBaseV1, IAmmOpenSwapServiceWstEth {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlySupportedInputAsset(address inputAsset) {
        if (inputAsset == asset) {
            _;
        } else {
            revert IporErrors.UnsupportedAsset(IporErrors.INPUT_ASSET_NOT_SUPPORTED, inputAsset);
        }
    }

    constructor(
        AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracle_
    ) AmmOpenSwapServiceBaseV1(poolCfg, iporOracle_) {}

    function openSwapPayFixed28daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override onlySupportedInputAsset(inputAsset) returns (uint256) {
        return
            _openSwapPayFixed(
                beneficiary,
                inputAsset,
                inputAssetTotalAmount,
                IporTypes.SwapTenor.DAYS_28,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed60daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override onlySupportedInputAsset(inputAsset) returns (uint256) {
        return
            _openSwapPayFixed(
                beneficiary,
                inputAsset,
                inputAssetTotalAmount,
                IporTypes.SwapTenor.DAYS_60,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed90daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override onlySupportedInputAsset(inputAsset) returns (uint256) {
        return
            _openSwapPayFixed(
                beneficiary,
                inputAsset,
                inputAssetTotalAmount,
                IporTypes.SwapTenor.DAYS_90,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed28daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override onlySupportedInputAsset(inputAsset) returns (uint256) {
        return
            _openSwapReceiveFixed(
                beneficiary,
                inputAsset,
                inputAssetTotalAmount,
                IporTypes.SwapTenor.DAYS_28,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed60daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override onlySupportedInputAsset(inputAsset) returns (uint256) {
        return
            _openSwapReceiveFixed(
                beneficiary,
                inputAsset,
                inputAssetTotalAmount,
                IporTypes.SwapTenor.DAYS_60,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed90daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override onlySupportedInputAsset(inputAsset) returns (uint256) {
        return
            _openSwapReceiveFixed(
                beneficiary,
                inputAsset,
                inputAssetTotalAmount,
                IporTypes.SwapTenor.DAYS_90,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function _getMessageSigner() internal view override returns (address) {
        return StorageLibArbitrum.getMessageSignerStorage().value;
    }

    function _convertToAssetAmount(
        address inputAsset,
        uint256 inputAssetAmount
    ) internal pure override returns (uint256) {
        /// @dev we supported only wstETH
        return inputAssetAmount;
    }

    function _convertInputAssetAmountToWadAmount(
        address,
        uint256 inputAssetAmount
    ) internal pure override returns (uint256) {
        /// @dev wstETH is represented in 18 decimals so no conversion is needed
        return inputAssetAmount;
    }

    function _validateInputAsset(address inputAsset, uint256 inputAssetTotalAmount) internal view override {
        if (inputAssetTotalAmount == 0) {
            revert IporErrors.InputAssetTotalAmountTooLow(
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                inputAssetTotalAmount
            );
        }

        uint256 accountBalance = IERC20Upgradeable(inputAsset).balanceOf(msg.sender);

        if (accountBalance < inputAssetTotalAmount) {
            revert IporErrors.InputAssetBalanceTooLow(
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                inputAsset,
                accountBalance,
                inputAssetTotalAmount
            );
        }
    }

    function _transferTotalAmountToAmmTreasury(address inputAsset, uint256 inputAssetTotalAmount) internal override {
        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, ammTreasury, inputAssetTotalAmount);
    }
}
