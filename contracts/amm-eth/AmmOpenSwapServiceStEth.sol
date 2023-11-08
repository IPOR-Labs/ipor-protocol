// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IIporOracle.sol";
import "../interfaces/IAmmStorage.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../interfaces/IAmmOpenSwapServiceStEth.sol";
import "../interfaces/IAmmOpenSwapLensStEth.sol";
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

/// @dev It is not recommended to use service contract directly, should be used only through IporProtocolRouter.
contract AmmOpenSwapServiceStEth is AmmOpenSwapServiceGenOne, IAmmOpenSwapServiceStEth, IAmmOpenSwapLensStEth {
    constructor(
        AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory poolCfg,
        address iporOracleInput,
        address messageSignerInput,
        address spreadRouterInput
    ) AmmOpenSwapServiceGenOne(poolCfg, iporOracleInput, messageSignerInput, spreadRouterInput) {}

    function getAmmOpenSwapServicePoolConfigurationStEth()
        external
        view
        override
        returns (AmmTypesGenOne.AmmOpenSwapServicePoolConfiguration memory)
    {
        return _getPoolConfiguration();
    }

    function openSwapPayFixed28daysStEth(
        address assetInput,
        address beneficiary,
        uint256 totalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external override returns (uint256) {
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
}
