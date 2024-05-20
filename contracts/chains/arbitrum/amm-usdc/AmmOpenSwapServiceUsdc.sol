// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


import {IporTypes} from "../../../interfaces/types/IporTypes.sol";
import {AmmTypes} from "../../../interfaces/types/AmmTypes.sol";
import {IporErrors} from "../../../libraries/errors/IporErrors.sol";
import {IporMath} from "../../../libraries/math/IporMath.sol";
import {IporContractValidator} from "../../../libraries/IporContractValidator.sol";
import {IAmmOpenSwapServiceUsdc} from "../interfaces/IAmmOpenSwapServiceUsdc.sol";
import {AmmTypesBaseV1} from "../../../base/types/AmmTypesBaseV1.sol";
import {AmmOpenSwapServiceBaseV1} from "../../../base/amm/services/AmmOpenSwapServiceBaseV1.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
contract AmmOpenSwapServiceUsdc is AmmOpenSwapServiceBaseV1, IAmmOpenSwapServiceUsdc {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporContractValidator for address;

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

    function getMessageSigner() public view override returns (address) {
        return StorageLibArbitrum.getMessageSignerStorage().value;
    }

    function openSwapPayFixed28daysUsdc(
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

    function openSwapPayFixed60daysUsdc(
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

    function openSwapPayFixed90daysUsdc(
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

    function openSwapReceiveFixed28daysUsdc(
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

    function openSwapReceiveFixed60daysUsdc(
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

    function openSwapReceiveFixed90daysUsdc(
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

    function _convertToAssetAmount(
        address inputAsset,
        uint256 inputAssetAmount
    ) internal pure override returns (uint256) {
        /// @dev we supported only USDC in USDC pool, validation in modifier onlySupportedInputAsset
        return inputAssetAmount;
    }

    function _convertInputAssetAmountToWadAmount(
        address inputAsset,
        uint256 inputAssetAmount
    ) internal view override returns (uint256) {
        /// @dev USDC is represented in 6 decimals
        return IporMath.convertToWad(inputAssetAmount, IERC20MetadataUpgradeable(inputAsset).decimals());
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

    function _transferTotalAmountToAmmTreasury(
        address inputAsset,
        uint256 inputAssetTotalAmount
    ) internal override {
        IERC20Upgradeable(asset).safeTransferFrom(msg.sender, ammTreasury, inputAssetTotalAmount);
    }
}
