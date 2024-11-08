// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPowerTokenLens} from "../../../interfaces/IPowerTokenLens.sol";
import {IPowerTokenFlowsService} from "../../../interfaces/IPowerTokenFlowsService.sol";
import {ILiquidityMiningLens} from "../../../interfaces/ILiquidityMiningLens.sol";
import {IPowerTokenStakeService} from "../../../interfaces/IPowerTokenStakeService.sol";
import {IAmmSwapsLens} from "../../../interfaces/IAmmSwapsLens.sol";
import {IAmmGovernanceLens} from "../../../interfaces/IAmmGovernanceLens.sol";
import {IAmmGovernanceService} from "../../../interfaces/IAmmGovernanceService.sol";
import {IAmmCloseSwapLens} from "../../../interfaces/IAmmCloseSwapLens.sol";
import {IAmmGovernanceServiceBaseV1} from "../../../base/interfaces/IAmmGovernanceServiceBaseV1.sol";
import {IAmmGovernanceLensBaseV1} from "../../../base/interfaces/IAmmGovernanceLensBaseV1.sol";
import {IAmmPoolsLensBaseV1} from "../../../base/interfaces/IAmmPoolsLensBaseV1.sol";
import {IAmmPoolsServiceUsdcBaseV1} from "../../../base/amm-usdc/interfaces/IAmmPoolsServiceUsdcBaseV1.sol";
import {IAmmOpenSwapServiceWstEth} from "../../../interfaces/IAmmOpenSwapServiceWstEth.sol";
import {IAmmCloseSwapServiceWstEth} from "../../../interfaces/IAmmCloseSwapServiceWstEth.sol";
import {IAmmPoolsServiceWstEthBaseV1} from "../../../base/amm-wstEth/interfaces/IAmmPoolsServiceWstEthBaseV1.sol";
import {IAmmOpenSwapServiceUsdcBaseV1} from "../../../base/amm-usdc/interfaces/IAmmOpenSwapServiceUsdcBaseV1.sol";
import {IAmmCloseSwapServiceUsdc} from "../../../interfaces/IAmmCloseSwapServiceUsdc.sol";
import {IAmmPoolsServiceUsdm} from "../../../amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import {IporErrors} from "../../../libraries/errors/IporErrors.sol";
import {IporContractValidator} from "../../../libraries/IporContractValidator.sol";
import {StorageLibBaseV1} from "../../../base/libraries/StorageLibBaseV1.sol";
import {IporProtocolRouterAbstract} from "../../../router/IporProtocolRouterAbstract.sol";

/// @title Entry point for IPOR protocol
contract IporProtocolRouterBase is IporProtocolRouterAbstract {
    using Address for address;
    using IporContractValidator for address;

    address public immutable ammSwapsLens;
    address public immutable ammPoolsLens;
    address public immutable ammCloseSwapLens;
    address public immutable ammGovernanceService;

    address public immutable flowService;
    address public immutable stakeService;
    address public immutable powerTokenLens;
    address public immutable liquidityMiningLens;

    address public immutable wstEth;
    address public immutable usdc;

    struct DeployedContractsBase {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammCloseSwapLens;
        address ammGovernanceService;
        address flowService;
        address stakeService;
        address powerTokenLens;
        address liquidityMiningLens;
        address wstEth;
        address usdc;
    }

    constructor(DeployedContractsBase memory deployedContracts) {
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

        _disableInitializers();
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContracts struct
    function getConfiguration() external view returns (DeployedContractsBase memory) {
        return
            DeployedContractsBase({
            ammSwapsLens: ammSwapsLens,
            ammPoolsLens: ammPoolsLens,
            ammCloseSwapLens: ammCloseSwapLens,
            ammGovernanceService: ammGovernanceService,
            flowService: flowService,
            stakeService: stakeService,
            powerTokenLens: powerTokenLens,
            liquidityMiningLens: liquidityMiningLens,
            wstEth: wstEth,
            usdc: usdc
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
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[wstEth];
            return servicesCfg.ammOpenSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceWstEth.closeSwapsWstEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[wstEth];
            return servicesCfg.ammCloseSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEthBaseV1.provideLiquidityWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEthBaseV1.redeemFromAmmPoolWstEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[wstEth];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdcBaseV1.provideLiquidityUsdcToAmmPoolUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdcBaseV1.redeemFromAmmPoolUsdc.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[usdc];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceUsdcBaseV1.openSwapPayFixed28daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceUsdcBaseV1.openSwapPayFixed60daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceUsdcBaseV1.openSwapPayFixed90daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceUsdcBaseV1.openSwapReceiveFixed28daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceUsdcBaseV1.openSwapReceiveFixed60daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceUsdcBaseV1.openSwapReceiveFixed90daysUsdc.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[usdc];
            return servicesCfg.ammOpenSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdc.closeSwapsUsdc.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[usdc];
            return servicesCfg.ammCloseSwapService;
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
            sig == IAmmGovernanceServiceBaseV1.setMessageSigner.selector ||
            sig == IAmmGovernanceServiceBaseV1.setAssetLensData.selector ||
            sig == IAmmGovernanceServiceBaseV1.setAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceServiceBaseV1.setAssetServices.selector
        ) {
            _onlyOwner();
            return ammGovernanceService;
        } else if (sig == IAmmCloseSwapServiceWstEth.emergencyCloseSwapsWstEth.selector) {
            _onlyOwner();
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1
                .getAssetServicesStorage()
                .value[wstEth];
            return servicesCfg.ammCloseSwapService;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceLensBaseV1.getMessageSigner.selector ||
            sig == IAmmGovernanceLensBaseV1.getAssetLensData.selector ||
            sig == IAmmGovernanceLensBaseV1.getAssetServices.selector
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
        } else if (sig == IAmmPoolsLensBaseV1.getIpTokenExchangeRate.selector) {
            return ammPoolsLens;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }
}
