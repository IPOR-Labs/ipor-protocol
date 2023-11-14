// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

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
import "../libraries/SwapEvents.sol";
import "../libraries/IporContractValidator.sol";
import "../libraries/RiskManagementLogic.sol";
import "../amm/libraries/types/AmmInternalTypes.sol";
import "../amm/libraries/IporSwapLogic.sol";
import "../basic/amm/services/AmmOpenSwapServiceGenOne.sol";
import "./interfaces/IAmmPoolsServiceEth.sol";
import "./interfaces/IStETH.sol";
import "./interfaces/IWETH9.sol";

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmOpenSwapServiceStEth is AmmOpenSwapServiceGenOne, IAmmOpenSwapServiceStEth {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20 for IStETH;
    using SafeERC20 for IWETH9;
    using IporContractValidator for address;

    address public immutable iporProtocolRouter;
    address public immutable wETH;

    constructor(
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address spreadRouterInput,
        address iporProtocolRouterInput,
        address wETHInput
    ) AmmOpenSwapServiceGenOne(poolCfg, iporOracleInput, messageSignerInput, spreadRouterInput) {
        iporProtocolRouter = iporProtocolRouterInput.checkAddress();
        wETH = wETHInput.checkAddress();
    }

    function openSwapPayFixed28daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external payable override returns (uint256) {
        return
            _openSwapPayFixed28days(
                assetInput,
                beneficiary,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed60daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override returns (uint256) {
        return
            _openSwapPayFixed60days(
                assetInput,
                beneficiary,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapPayFixed90daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override returns (uint256) {
        return
            _openSwapPayFixed90days(
                assetInput,
                beneficiary,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed28daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override returns (uint256) {
        return
            _openSwapReceiveFixed28days(
                assetInput,
                beneficiary,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed60daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override returns (uint256) {
        return
            _openSwapReceiveFixed60days(
                assetInput,
                beneficiary,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function openSwapReceiveFixed90daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override returns (uint256) {
        return
            _openSwapReceiveFixed90days(
                assetInput,
                beneficiary,
                totalAmount,
                acceptableFixedInterestRate,
                leverage,
                riskIndicatorsInputs
            );
    }

    function _transferAssetInputToAmmTreasury(address assetInput, uint256 totalAmount) internal override {
        if (assetInput == address(0)) {
            require(msg.value == totalAmount, "Wrong amount");
            _submitEth(totalAmount);
        } else if (assetInput == asset) {
            IERC20Upgradeable(assetInput).safeTransferFrom(msg.sender, ammTreasury, totalAmount);
        } else if (assetInput == wETH) {
            IWETH9(wETH).safeTransferFrom(msg.sender, iporProtocolRouter, totalAmount);

            /// @dev WETH -> ETH
            IWETH9(wETH).withdraw(totalAmount);

            _submitEth(totalAmount);
        } else {
            revert("Wrong input address");
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
