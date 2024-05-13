// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IAmmOpenSwapServiceStEth.sol";
import "./interfaces/IStETH.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IwstEth.sol";
import "./interfaces/IAmmPoolsServiceStEth.sol";
import "../base/amm/services/AmmOpenSwapServiceBaseV1.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
/// @dev Service can be safely used directly only if you are sure that methods will not touch any storage variables.
contract AmmOpenSwapServiceStEth is AmmOpenSwapServiceBaseV1, IAmmOpenSwapServiceStEth {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using IporContractValidator for address;

    address public immutable wETH;
    address public immutable wstETH;

    modifier onlySupportedInputAsset(address inputAsset) {
        if (inputAsset == asset || inputAsset == wETH || inputAsset == ETH_ADDRESS || inputAsset == wstETH) {
            _;
        } else {
            revert IporErrors.UnsupportedAsset(IporErrors.INPUT_ASSET_NOT_SUPPORTED, inputAsset);
        }
    }

    constructor(
        AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address wETHInput,
        address wstETHInput
    ) AmmOpenSwapServiceBaseV1(poolCfg, iporOracleInput, messageSignerInput) {
        wETH = wETHInput.checkAddress();
        wstETH = wstETHInput.checkAddress();
    }

    function openSwapPayFixed28daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override onlySupportedInputAsset(inputAsset) returns (uint256) {
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

    function openSwapPayFixed60daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override onlySupportedInputAsset(inputAsset) returns (uint256) {
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

    function openSwapPayFixed90daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override onlySupportedInputAsset(inputAsset) returns (uint256) {
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

    function openSwapReceiveFixed28daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override onlySupportedInputAsset(inputAsset) returns (uint256) {
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

    function openSwapReceiveFixed60daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override onlySupportedInputAsset(inputAsset) returns (uint256) {
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

    function openSwapReceiveFixed90daysStEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override onlySupportedInputAsset(inputAsset) returns (uint256) {
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
    ) internal view override returns (uint256) {
        if (inputAsset == asset || inputAsset == wETH || inputAsset == ETH_ADDRESS) {
            /// @dev entered asset is in relation 1:1 with underlying asset (stETH)
            return inputAssetAmount;
        } else if (inputAsset == wstETH) {
            return IwstEth(wstETH).getStETHByWstETH(inputAssetAmount);
        }
        return 0;
    }

    function _convertInputAssetAmountToWadAmount(
        address,
        uint256 inputAssetAmount
    ) internal pure override returns (uint256) {
        /// @dev stETH, wETH, ETH, wstETH are represented in 18 decimals so no conversion is needed
        return inputAssetAmount;
    }

    function _validateInputAsset(address inputAsset, uint256 inputAssetTotalAmount) internal view override {
        if (inputAssetTotalAmount == 0) {
            revert IporErrors.InputAssetTotalAmountTooLow(
                IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                inputAssetTotalAmount
            );
        }

        if (inputAsset == ETH_ADDRESS) {
            if (msg.value < inputAssetTotalAmount) {
                revert IporErrors.InputAssetBalanceTooLow(
                    IporErrors.SENDER_ASSET_BALANCE_TOO_LOW,
                    ETH_ADDRESS,
                    msg.value,
                    inputAssetTotalAmount
                );
            }
        } else {
            if (inputAsset == wETH || inputAsset == asset || inputAsset == wstETH) {
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
        }
    }

    /// @param inputAsset - input asset address (ETH, wETH, stETH, wstETH) entered by user
    /// @param inputAssetTotalAmount - total amount of input asset entered by user, value represented in decimals of input asset
    function _transferTotalAmountToAmmTreasury(
        address inputAsset,
        uint256 inputAssetTotalAmount
    ) internal override {
        if (inputAsset == ETH_ADDRESS) {
            _submitEth(inputAssetTotalAmount);
        } else if (inputAsset == asset) {
            IERC20Upgradeable(inputAsset).safeTransferFrom(msg.sender, ammTreasury, inputAssetTotalAmount);
        } else if (inputAsset == wETH) {
            IERC20Upgradeable(wETH).safeTransferFrom(msg.sender, address(this), inputAssetTotalAmount);

            /// @dev swap in relation 1:1 wETH -> ETH
            IWETH9(wETH).withdraw(inputAssetTotalAmount);

            _submitEth(inputAssetTotalAmount);
        } else if (inputAsset == wstETH) {
            IERC20Upgradeable(wstETH).safeTransferFrom(msg.sender, address(this), inputAssetTotalAmount);

            uint256 stEthAmount = IwstEth(wstETH).unwrap(inputAssetTotalAmount);

            if (stEthAmount > 0) {
                IERC20Upgradeable(asset).safeTransfer(ammTreasury, stEthAmount);
            }
        }
    }

    function _submitEth(uint256 totalAmountEth) internal {
        /// @dev _asset = stETH
        /// @dev ETH -> stETH
        try IStETH(asset).submit{value: totalAmountEth}(address(0)) {
            uint256 stEthAmount = IStETH(asset).balanceOf(address(this));

            if (stEthAmount > 0) {
                IERC20Upgradeable(asset).safeTransfer(ammTreasury, stEthAmount);
            }
        } catch {
            revert IAmmPoolsServiceStEth.StEthSubmitFailed({
                amount: totalAmountEth,
                errorCode: AmmErrors.STETH_SUBMIT_FAILED
            });
        }
    }
}
