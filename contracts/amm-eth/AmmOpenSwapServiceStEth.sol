// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IAmmOpenSwapServiceStEth.sol";
import "./interfaces/IStETH.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IwstEth.sol";
import "./interfaces/IAmmPoolsServiceStEth.sol";
import "../basic/amm/services/AmmOpenSwapServiceGenOne.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmOpenSwapServiceStEth is AmmOpenSwapServiceGenOne, IAmmOpenSwapServiceStEth {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20 for IStETH;
    using SafeERC20 for IWETH9;
    using SafeERC20 for IwstEth;
    using IporContractValidator for address;

    address public immutable iporProtocolRouter;
    address public immutable wETH;
    address public immutable wstETH;

    constructor(
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address iporProtocolRouterInput,
        address wETHInput,
        address wstETHInput
    ) AmmOpenSwapServiceGenOne(poolCfg, iporOracleInput, messageSignerInput) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        wETH = wETHInput.checkAddress();
        wstETH = wstETHInput.checkAddress();
    }

    function openSwapPayFixed28daysStEth(
        address inputAsset,
        address beneficiary,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed(
                inputAsset,
                beneficiary,
                IporTypes.SwapTenor.DAYS_28,
                inputAssetTotalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed60daysStEth(
        address inputAsset,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed(
                inputAsset,
                beneficiary,
                IporTypes.SwapTenor.DAYS_60,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed90daysStEth(
        address inputAsset,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed(
                inputAsset,
                beneficiary,
                IporTypes.SwapTenor.DAYS_90,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed28daysStEth(
        address inputAsset,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapReceiveFixed(
                inputAsset,
                beneficiary,
                IporTypes.SwapTenor.DAYS_28,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed60daysStEth(
        address inputAsset,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapReceiveFixed(
                inputAsset,
                beneficiary,
                IporTypes.SwapTenor.DAYS_60,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed90daysStEth(
        address inputAsset,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapReceiveFixed(
                inputAsset,
                beneficiary,
                IporTypes.SwapTenor.DAYS_90,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function _convertToAssetAmount(address inputAsset, uint256 inputAssetAmount) internal view override returns (uint256) {
        if (inputAsset == asset || inputAsset == wETH || inputAsset == ETH_ADDRESS) {
            /// @dev entered asset is in relation 1:1 with underlying asset (stETH)
            return inputAssetAmount;
        } else if (inputAsset == wstETH) {
            return IwstEth(wstETH).getStETHByWstETH(inputAssetAmount);
        }

        revert IporErrors.UnsupportedAsset(inputAsset);
    }

    function _convertInputAssetAmountToWadAmount(
        address inputAsset,
        uint256 inputAssetAmount
    ) internal view override returns (uint256) {
        if (inputAsset == asset || inputAsset == wETH || inputAsset == ETH_ADDRESS || inputAsset == wstETH) {
            /// @dev stETH, wETH, ETH, wstETH are represented in 18 decimals so no conversion is needed
            return inputAssetAmount;
        }
        revert IporErrors.UnsupportedAsset(inputAsset);
    }

    function _validateInputAsset(address inputAsset, uint256 inputAssetTotalAmount) internal view override {
        if (inputAssetTotalAmount <= 0) {
            revert IporErrors.InputAssetTotalAmountTooLow(inputAssetTotalAmount);
        }

        if (inputAsset == ETH_ADDRESS) {
            if (msg.value < inputAssetTotalAmount) {
                revert IporErrors.InputAssetBalanceTooLow(ETH_ADDRESS, msg.value, inputAssetTotalAmount);
            }
        } else {
            if (inputAsset == wETH || inputAsset == asset || inputAsset == wstETH) {
                uint256 accountBalance = IERC20Upgradeable(inputAsset).balanceOf(msg.sender);

                if (accountBalance < inputAssetTotalAmount) {
                    revert IporErrors.InputAssetBalanceTooLow(inputAsset, accountBalance, inputAssetTotalAmount);
                }
            } else {
                revert IporErrors.UnsupportedAsset(inputAsset);
            }
        }
    }

    /// @param inputAsset - input asset address (ETH, wETH, stETH, wstETH) entered by user
    /// @param inputAssetTotalAmount - total amount of input asset entered by user, value represented in decimals of input asset
    /// @param assetTotalAmount - total amount of underlying asset (stETH) calculated by service, takes into consideration exchange rate of input asset, value represented in decimals of underlying asset
    function _transferTotalAmountToAmmTreasury(
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 assetTotalAmount
    ) internal override {
        if (inputAsset == ETH_ADDRESS) {
            if (msg.value < inputAssetTotalAmount) {
                revert IporErrors.WrongAmount("msg.value", msg.value);
            }
            _submitEth(inputAssetTotalAmount);
        } else if (inputAsset == asset) {
            IERC20Upgradeable(inputAsset).safeTransferFrom(msg.sender, ammTreasury, inputAssetTotalAmount);
        } else if (inputAsset == wETH) {
            IWETH9(wETH).safeTransferFrom(msg.sender, iporProtocolRouter, inputAssetTotalAmount);

            /// @dev swap in relation 1:1 wETH -> ETH
            IWETH9(wETH).withdraw(inputAssetTotalAmount);

            _submitEth(inputAssetTotalAmount);
        } else if (inputAsset == wstETH) {
            IwstEth(wstETH).safeTransferFrom(msg.sender, address(this), inputAssetTotalAmount);

            uint256 stEthAmount = IwstEth(wstETH).unwrap(inputAssetTotalAmount);

            if (stEthAmount > 0) {
                IStETH(asset).safeTransfer(ammTreasury, stEthAmount);
            }
        } else {
            revert IporErrors.UnsupportedAsset(inputAsset);
        }
    }

    function _submitEth(uint256 totalAmount) internal {
        /// @dev _asset = stETH
        /// @dev ETH -> stETH
        try IStETH(asset).submit{value: totalAmount}(address(0)) {
            uint256 stEthAmount = IStETH(asset).balanceOf(address(this));

            if (stEthAmount > 0) {
                IStETH(asset).safeTransfer(ammTreasury, stEthAmount);
            }
        } catch {
            revert IAmmPoolsServiceStEth.StEthSubmitFailed({
                amount: totalAmount,
                errorCode: AmmErrors.STETH_SUBMIT_FAILED
            });
        }
    }
}
