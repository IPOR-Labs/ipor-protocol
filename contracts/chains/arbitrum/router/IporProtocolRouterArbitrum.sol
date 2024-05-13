// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/IAmmSwapsLens.sol";
import "../../../interfaces/IAmmPoolsLens.sol";
import "../../../interfaces/IPowerTokenLens.sol";
import "../../../interfaces/ILiquidityMiningLens.sol";
import "../../../interfaces/IAmmGovernanceService.sol";
import {StorageLibArbitrum} from "../libraries/StorageLibArbitrum.sol";
import {IAmmGovernanceServiceArbitrum} from "../interfaces/IAmmGovernanceServiceArbitrum.sol";
import {IAmmGovernanceLensArbitrum} from "../interfaces/IAmmGovernanceLensArbitrum.sol";
import "../../../interfaces/IAmmGovernanceLens.sol";
import "../../../interfaces/IAmmOpenSwapLens.sol";
import "../../../interfaces/IAmmOpenSwapServiceWstEth.sol";
import "../../../interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../interfaces/IAmmCloseSwapLens.sol";
import "../../../interfaces/IPowerTokenFlowsService.sol";
import "../../../interfaces/IPowerTokenStakeService.sol";
import "../../../amm-eth/interfaces/IAmmPoolsServiceWstEth.sol";
import "../../../amm-eth/interfaces/IAmmPoolsLensWstEth.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../router/IporProtocolRouterAbstract.sol";
import {IAmmPoolsLensArbitrum} from "../amm-commons/AmmPoolsLensArbitrum.sol";
import "../../../amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import "../../../amm-usdm/interfaces/IAmmPoolsLensUsdm.sol";

/// @title Entry point for IPOR protocol
contract IporProtocolRouterArbitrum is IporProtocolRouterAbstract {
    using Address for address;
    using IporContractValidator for address;

    address public immutable wstEth;
    address public immutable usdc;
    address public immutable usdm;

    address public immutable ammSwapsLens;
    address public immutable ammPoolsLens;
    address public immutable ammCloseSwapLens;
    address public immutable ammGovernanceService;

    address public immutable flowService;
    address public immutable stakeService;
    address public immutable powerTokenLens;
    address public immutable liquidityMiningLens;

    struct DeployedContractsArbitrum {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammCloseSwapLens;
        address ammGovernanceService;

        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;

        address wstEth;
        address usdc;
        address usdm;
    }

    constructor(DeployedContractsArbitrum memory deployedContracts) {
        ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();

        liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();
        powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        flowService = deployedContracts.flowService.checkAddress();
        stakeService = deployedContracts.stakeService.checkAddress();

        wstEth = deployedContracts.wstEth.checkAddress();
        usdc = deployedContracts.usdc.checkAddress();
        usdm = deployedContracts.usdm.checkAddress();

        _disableInitializers();
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContracts struct
    function getConfiguration() external view returns (DeployedContractsArbitrum memory) {
        return
            DeployedContractsArbitrum({
            ammSwapsLens: ammSwapsLens,
            ammPoolsLens: ammPoolsLens,
            ammCloseSwapLens: ammCloseSwapLens,
            ammGovernanceService: ammGovernanceService,

            liquidityMiningLens: liquidityMiningLens,
            powerTokenLens: powerTokenLens,
            flowService: flowService,
            stakeService: stakeService,

            wstEth: wstEth,
            usdc: usdc,
            usdm: usdm
        });
    }

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal override returns (address) {
        if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapPayFixed28daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapPayFixed60daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapPayFixed90daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapReceiveFixed28daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapReceiveFixed60daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapReceiveFixed90daysWstEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibArbitrum.AssetServicesValue storage servicesCfg = StorageLibArbitrum.getAssetServicesStorage().value[wstEth];
            return servicesCfg.ammOpenSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceWstEth.closeSwapsWstEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibArbitrum.AssetServicesValue storage servicesCfg = StorageLibArbitrum.getAssetServicesStorage().value[wstEth];
            return servicesCfg.ammCloseSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEth.provideLiquidityWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEth.redeemFromAmmPoolWstEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibArbitrum.AssetServicesValue storage servicesCfg = StorageLibArbitrum.getAssetServicesStorage().value[wstEth];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.provideLiquidityUsdmToAmmPoolUsdm.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.redeemFromAmmPoolUsdm.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibArbitrum.AssetServicesValue storage servicesCfg = StorageLibArbitrum.getAssetServicesStorage().value[usdm];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.stakeLpTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.unstakeLpTokensFromLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.stakeGovernanceTokenToPowerToken.selector) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenStakeService.stakeGovernanceTokenToPowerTokenAndDelegate.selector
            ) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenStakeService.unstakeGovernanceTokenFromPowerToken.selector
            ) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.pwTokenCooldown.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.pwTokenCancelCooldown.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.redeemPwToken.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return stakeService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.delegatePwTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.updateIndicatorsInLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenFlowsService.undelegatePwTokensFromLiquidityMining.selector
            ) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.claimRewardsFromLiquidityMining.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return flowService;
        } else if (
            sig == IAmmGovernanceService.transferToTreasury.selector ||
            sig == IAmmGovernanceService.transferToCharlieTreasury.selector
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammGovernanceService;
        } else if (
            sig == IAmmGovernanceService.addSwapLiquidator.selector ||
            sig == IAmmGovernanceService.removeSwapLiquidator.selector ||
            sig == IAmmGovernanceService.addAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.removeAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.depositToAssetManagement.selector ||
            sig == IAmmGovernanceService.withdrawFromAssetManagement.selector ||
            sig == IAmmGovernanceService.withdrawAllFromAssetManagement.selector ||
            sig == IAmmGovernanceService.setAmmPoolsParams.selector ||
            sig == IAmmGovernanceServiceArbitrum.setIporIndexOracle.selector ||
            sig == IAmmGovernanceServiceArbitrum.setMessageSigner.selector ||
            sig == IAmmGovernanceServiceArbitrum.setAssetLensData.selector ||
            sig == IAmmGovernanceServiceArbitrum.setAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceServiceArbitrum.setAssetServices.selector
        ) {
            _onlyOwner();
            return ammGovernanceService;
        } else if (sig == IAmmCloseSwapServiceWstEth.emergencyCloseSwapsWstEth.selector) {
            _onlyOwner();
            StorageLibArbitrum.AssetServicesValue storage servicesCfg = StorageLibArbitrum.getAssetServicesStorage().value[wstEth];
            return servicesCfg.ammCloseSwapService;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceLensArbitrum.getIporIndexOracle.selector ||
            sig == IAmmGovernanceLensArbitrum.getMessageSigner.selector ||
            sig == IAmmGovernanceLensArbitrum.getAssetLensData.selector ||
            sig == IAmmGovernanceLensArbitrum.getAssetServices.selector
        ) {
            return ammGovernanceService;
        } else if (
            sig == IAmmSwapsLens.getSwaps.selector ||
            sig == IAmmSwapsLens.getPnlPayFixed.selector ||
            sig == IAmmSwapsLens.getPnlReceiveFixed.selector ||
            sig == IAmmSwapsLens.getBalancesForOpenSwap.selector ||
            sig == IAmmSwapsLens.getSoap.selector ||
            sig == IAmmSwapsLens.getOfferedRate.selector ||
            sig == IAmmSwapsLens.getSwapLensPoolConfiguration.selector
        ) {
            return ammSwapsLens;
        } else if (
            sig == ILiquidityMiningLens.balanceOfLpTokensStakedInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.balanceOfPowerTokensDelegatedToLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccruedRewardsInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getGlobalIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountRewardsInLiquidityMining.selector
        ) {
            return liquidityMiningLens;
        } else if (
            sig == IPowerTokenLens.totalSupplyOfPwToken.selector ||
            sig == IPowerTokenLens.balanceOfPwToken.selector ||
            sig == IPowerTokenLens.balanceOfPwTokenDelegatedToLiquidityMining.selector ||
            sig == IPowerTokenLens.getPwTokensInCooldown.selector ||
            sig == IPowerTokenLens.getPwTokenUnstakeFee.selector ||
            sig == IPowerTokenLens.getPwTokenCooldownTime.selector ||
            sig == IPowerTokenLens.getPwTokenExchangeRate.selector ||
            sig == IPowerTokenLens.getPwTokenTotalSupplyBase.selector
        ) {
            return powerTokenLens;
        } else if (
            sig == IAmmCloseSwapLens.getAmmCloseSwapServicePoolConfiguration.selector ||
            sig == IAmmCloseSwapLens.getClosingSwapDetails.selector
        ) {
            return ammCloseSwapLens;
        }
        else if (sig == IAmmPoolsLensArbitrum.getIpTokenExchangeRate.selector) {
            return ammPoolsLens;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }
}
