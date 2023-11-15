// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;
import "forge-std/console2.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../interfaces/IAmmOpenSwapServiceStEth.sol";
import "../amm/spread/ISpread28Days.sol";
import "../amm/spread/ISpread60Days.sol";
import "../amm/spread/ISpread90Days.sol";
import "../libraries/Constants.sol";
import "../libraries/math/IporMath.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/errors/AmmErrors.sol";
import "../basic/amm/libraries/SwapEventsGenOne.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/RiskManagementLogic.sol";
import "../amm/libraries/types/AmmInternalTypes.sol";
import "../amm/libraries/IporSwapLogic.sol";
import "../basic/amm/services/AmmOpenSwapServiceGenOne.sol";
import "./interfaces/IAmmPoolsServiceEth.sol";
import "./interfaces/IStETH.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/IwstEth.sol";

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
        address spreadInput,
        address iporProtocolRouterInput,
        address wETHInput,
        address wstETHInput
    ) AmmOpenSwapServiceGenOne(poolCfg, iporOracleInput, messageSignerInput, spreadInput) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        wETH = wETHInput.checkAddress();
        wstETH = wstETHInput.checkAddress();
    }

    function openSwapPayFixed28daysStEth(
        address accountInputToken,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed(
                accountInputToken,
                beneficiary,
                IporTypes.SwapTenor.DAYS_28,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed60daysStEth(
        address accountInputToken,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed(
                accountInputToken,
                beneficiary,
                IporTypes.SwapTenor.DAYS_60,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed90daysStEth(
        address accountInputToken,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed(
                accountInputToken,
                beneficiary,
                IporTypes.SwapTenor.DAYS_90,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed28daysStEth(
        address accountInputToken,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapReceiveFixed(
                accountInputToken,
                beneficiary,
                IporTypes.SwapTenor.DAYS_28,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed60daysStEth(
        address accountInputToken,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapReceiveFixed(
                accountInputToken,
                beneficiary,
                IporTypes.SwapTenor.DAYS_60,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed90daysStEth(
        address accountInputToken,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapReceiveFixed(
                accountInputToken,
                beneficiary,
                IporTypes.SwapTenor.DAYS_90,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function _validateTotalAmount(address accountInputToken, uint256 totalAmount) internal view override {
        require(totalAmount > 0, AmmErrors.TOTAL_AMOUNT_TOO_LOW);

        if (accountInputToken == ETH_ADDRESS) {
            if (msg.value != totalAmount) {
                revert IporErrors.AccountInputTokenBalanceTooLow(ETH_ADDRESS, msg.value, totalAmount);
            }
        } else {
            uint256 accountBalance = IERC20Upgradeable(accountInputToken).balanceOf(msg.sender);

            if (accountInputToken == wETH || accountInputToken == asset) {
                if (accountBalance < totalAmount) {
                    revert IporErrors.AccountInputTokenBalanceTooLow(accountInputToken, accountBalance, totalAmount);
                }
            } else if (accountInputToken == wstETH) {
                uint256 inputTokenTotalAmount = IporMath.division(IwstEth(wstETH).tokensPerStEth() * totalAmount, 1e18);
                console2.log("accountBalance", accountBalance);
                console2.log("inputTokenTotalAmount", inputTokenTotalAmount);

                if (accountBalance < inputTokenTotalAmount) {
                    revert IporErrors.AccountInputTokenBalanceTooLow(
                        accountInputToken,
                        accountBalance,
                        inputTokenTotalAmount
                    );
                }
            }
        }
    }

    function _transferAssetInputToAmmTreasury(
        address accountInputToken,
        uint256 totalAmount
    ) internal override returns (uint256 accountInputTokenAmount) {
        if (accountInputToken == ETH_ADDRESS) {
            if (msg.value != totalAmount) {
                revert IporErrors.WrongAmount("msg.value", msg.value);
            }
            _submitEth(totalAmount);
            accountInputTokenAmount = totalAmount;
        } else if (accountInputToken == asset) {
            IERC20Upgradeable(accountInputToken).safeTransferFrom(msg.sender, ammTreasury, totalAmount);
            accountInputTokenAmount = totalAmount;
        } else if (accountInputToken == wETH) {
            IWETH9(wETH).safeTransferFrom(msg.sender, iporProtocolRouter, totalAmount);

            /// @dev WETH -> ETH
            IWETH9(wETH).withdraw(totalAmount);

            _submitEth(totalAmount);
            accountInputTokenAmount = totalAmount;
        } else if (accountInputToken == wstETH) {
            /// @dev wstETH -> stETH
            uint256 tokensPerStEth = IwstEth(wstETH).tokensPerStEth();

            accountInputTokenAmount = IporMath.division(tokensPerStEth * totalAmount, 1e18);

            IwstEth(wstETH).safeTransferFrom(msg.sender, address(this), accountInputTokenAmount);

            uint256 stEthAmount = IwstEth(wstETH).unwrap(accountInputTokenAmount);

            if (stEthAmount > 0) {
                IStETH(asset).safeTransfer(ammTreasury, stEthAmount);
            }
        } else {
            revert IporErrors.UnsupportedAsset(accountInputToken);
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
            revert IAmmPoolsServiceEth.StEthSubmitFailed({
                amount: totalAmount,
                errorCode: AmmErrors.STETH_SUBMIT_FAILED
            });
        }
    }
}
