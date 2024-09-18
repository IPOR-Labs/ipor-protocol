// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/IAmmSwapsLens.sol";
import "../../../interfaces/IAmmPoolsLens.sol";
import "../../../interfaces/IPowerTokenLens.sol";
import "../../../interfaces/ILiquidityMiningLens.sol";
import "../../../interfaces/IAmmGovernanceService.sol";
import "../../../interfaces/IAmmGovernanceLens.sol";
import "../../../interfaces/IAmmOpenSwapLens.sol";
import "../../../interfaces/IAmmOpenSwapService.sol";
import "../../../interfaces/IAmmOpenSwapServiceStEth.sol";
import "../../../interfaces/IAmmCloseSwapServiceUsdt.sol";
import "../../../interfaces/IAmmCloseSwapServiceUsdc.sol";
import "../../../interfaces/IAmmCloseSwapServiceDai.sol";
import "../../../interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../../interfaces/IAmmCloseSwapLens.sol";
import "../../../interfaces/IPowerTokenFlowsService.sol";
import "../../../interfaces/IPowerTokenStakeService.sol";
import "../../../amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import "../../../amm-weEth/interfaces/IAmmPoolsServiceWeEth.sol";
import "../../../amm-eth/interfaces/IAmmPoolsLensStEth.sol";
import "../../../amm-weEth/interfaces/IAmmPoolsLensWeEth.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../router/IporProtocolRouterAbstract.sol";
import "../../../amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import "../../../amm-usdm/interfaces/IAmmPoolsLensUsdm.sol";
import {IAmmPoolsLensEthereum} from "../interfaces/IAmmPoolsLensEthereum.sol";
import {IAmmPoolsServiceUsdt} from "../interfaces/IAmmPoolsServiceUsdt.sol";
import {IAmmPoolsServiceUsdc} from "../interfaces/IAmmPoolsServiceUsdc.sol";
import {IAmmPoolsServiceDai} from "../interfaces/IAmmPoolsServiceDai.sol";
import {IAmmGovernanceServiceEthereum} from "../interfaces/IAmmGovernanceServiceEthereum.sol";
import {IAmmGovernanceLensEthereum} from "../interfaces/IAmmGovernanceLensEthereum.sol";
import {StorageLibEthereum} from "../libraries/StorageLibEthereum.sol";

/// @title Entry point for IPOR protocol
contract IporProtocolRouterEthereum is IporProtocolRouterAbstract {
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

    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;
    address public immutable stEth;
    address public immutable weEth;
    address public immutable usdm;

    struct DeployedContractsEthereum {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammCloseSwapLens;
        address ammGovernanceService;
        address flowService;
        address stakeService;
        address powerTokenLens;
        address liquidityMiningLens;
        address usdt;
        address usdc;
        address dai;
        address stEth;
        address weEth;
        address usdm;
    }

    constructor(DeployedContractsEthereum memory deployedContracts) {
        ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();
        flowService = deployedContracts.flowService.checkAddress();
        stakeService = deployedContracts.stakeService.checkAddress();
        powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();

        usdt = deployedContracts.usdt.checkAddress();
        usdc = deployedContracts.usdc.checkAddress();
        dai = deployedContracts.dai.checkAddress();
        stEth = deployedContracts.stEth.checkAddress();
        weEth = deployedContracts.weEth.checkAddress();
        usdm = deployedContracts.usdm.checkAddress();

        _disableInitializers();
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContractsEthereum struct
    function getConfiguration() external view returns (DeployedContractsEthereum memory) {
        return
            DeployedContractsEthereum({
            ammSwapsLens: ammSwapsLens,
            ammPoolsLens: ammPoolsLens,
            ammCloseSwapLens: ammCloseSwapLens,
            ammGovernanceService: ammGovernanceService,
            flowService: flowService,
            stakeService: stakeService,
            powerTokenLens: powerTokenLens,
            liquidityMiningLens: liquidityMiningLens,
            usdt: usdt,
            usdc: usdc,
            dai: dai,
            stEth: stEth,
            weEth: weEth,
            usdm: usdm
        });
    }

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal override returns (address) {
        if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceStEth.openSwapPayFixed28daysStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceStEth.openSwapPayFixed60daysStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceStEth.openSwapPayFixed90daysStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceStEth.openSwapReceiveFixed28daysStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceStEth.openSwapReceiveFixed60daysStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceStEth.openSwapReceiveFixed90daysStEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[stEth];

            return servicesCfg.ammOpenSwapService;

        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed60daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed28daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed90daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed28daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed60daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed90daysUsdt.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdt];

            return servicesCfg.ammOpenSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed28daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed60daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed90daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed28daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed60daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed90daysUsdc.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdc];

            return servicesCfg.ammOpenSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed28daysDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed60daysDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed90daysDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed28daysDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed60daysDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed90daysDai.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[dai];

            return servicesCfg.ammOpenSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceStEth.closeSwapsStEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[stEth];
            return servicesCfg.ammCloseSwapService;

        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdt.closeSwapsUsdt.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdt];
            return servicesCfg.ammCloseSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdc.closeSwapsUsdc.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdc];
            return servicesCfg.ammCloseSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceDai.closeSwapsDai.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[dai];
            return servicesCfg.ammCloseSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityWEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.redeemFromAmmPoolStEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[stEth];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.provideLiquidityWeEthToAmmPoolWeEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.provideLiquidity.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.redeemFromAmmPoolWeEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[weEth];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdt.provideLiquidityUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdt.redeemFromAmmPoolUsdt.selector)
        ) {
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdt];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdc.provideLiquidityUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdc.redeemFromAmmPoolUsdc.selector)
        ) {
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdc];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceDai.provideLiquidityDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceDai.redeemFromAmmPoolDai.selector)
        ) {
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[dai];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.provideLiquidityUsdmToAmmPoolUsdm.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.redeemFromAmmPoolUsdm.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdm];
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
            sig == IAmmGovernanceServiceEthereum.setMessageSigner.selector ||
            sig == IAmmGovernanceServiceEthereum.setAssetLensData.selector ||
            sig == IAmmGovernanceServiceEthereum.setAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceServiceEthereum.setAssetServices.selector
        ) {
            _onlyOwner();
            return ammGovernanceService;
        } else if (sig == IAmmCloseSwapServiceUsdt.emergencyCloseSwapsUsdt.selector) {
            _onlyOwner();
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdt];
            return servicesCfg.ammCloseSwapService;
        } else if (sig == IAmmCloseSwapServiceUsdc.emergencyCloseSwapsUsdc.selector) {
            _onlyOwner();
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[usdc];
            return servicesCfg.ammCloseSwapService;
        } else if (sig == IAmmCloseSwapServiceDai.emergencyCloseSwapsDai.selector) {
            _onlyOwner();
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[dai];
            return servicesCfg.ammCloseSwapService;
        } else if (sig == IAmmCloseSwapServiceStEth.emergencyCloseSwapsStEth.selector) {
            _onlyOwner();
            StorageLibEthereum.AssetServicesValue storage servicesCfg = StorageLibEthereum
                .getAssetServicesStorage()
                .value[stEth];
            return servicesCfg.ammCloseSwapService;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceLensEthereum.getMessageSigner.selector ||
            sig == IAmmGovernanceLensEthereum.getAssetLensData.selector ||
            sig == IAmmGovernanceLensEthereum.getAssetServices.selector
        ) {
            return ammGovernanceService;
//        } else if (sig == IAmmOpenSwapLens.getAmmOpenSwapServicePoolConfiguration.selector) {
//            return ammOpenSwapService;
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
//        } else if (
//            sig == IAmmPoolsLens.getAmmPoolsLensConfiguration.selector ||
//            sig == IAmmPoolsLens.getIpTokenExchangeRate.selector ||
//            sig == IAmmPoolsLens.getAmmBalance.selector
//        ) {
//            return ammPoolsLens;
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
        } else if (sig == IAmmPoolsLensEthereum.getIpTokenExchangeRate.selector) {
            return ammPoolsLens;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }
}
