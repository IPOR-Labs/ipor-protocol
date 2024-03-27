// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/IAmmSwapsLens.sol";
import "../../../interfaces/IAmmPoolsLens.sol";
import "../../../interfaces/IAssetManagementLens.sol";
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
import "../../../interfaces/IAmmPoolsService.sol";
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

/// @title Entry point for IPOR protocol
contract IporProtocolRouter is IporProtocolRouterAbstract {
    using Address for address;
    using IporContractValidator for address;

    address public immutable ammSwapsLens;
    address public immutable ammPoolsLens;
    address public immutable assetManagementLens;
    address public immutable ammOpenSwapService;
    address public immutable ammOpenSwapServiceStEth;
    address public immutable ammCloseSwapServiceUsdt;
    address public immutable ammCloseSwapServiceUsdc;
    address public immutable ammCloseSwapServiceDai;
    address public immutable ammCloseSwapServiceStEth;
    address public immutable ammCloseSwapLens;
    address public immutable ammPoolsService;
    address public immutable ammGovernanceService;
    address public immutable liquidityMiningLens;
    address public immutable powerTokenLens;
    address public immutable flowService;
    address public immutable stakeService;
    address public immutable ammPoolsServiceStEth;
    address public immutable ammPoolsLensStEth;
    address public immutable ammPoolsServiceWeEth;
    address public immutable ammPoolsLensWeEth;
    address public immutable ammPoolsServiceUsdm;
    address public immutable ammPoolsLensUsdm;

    struct DeployedContracts {
        address ammSwapsLens;
        address ammPoolsLens;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammOpenSwapServiceStEth;
        address ammCloseSwapServiceUsdt;
        address ammCloseSwapServiceUsdc;
        address ammCloseSwapServiceDai;
        address ammCloseSwapServiceStEth;
        address ammCloseSwapLens;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
        address ammPoolsServiceStEth;
        address ammPoolsLensStEth;
        address ammPoolsServiceWeEth;
        address ammPoolsLensWeEth;
        address ammPoolsServiceUsdm;
        address ammPoolsLensUsdm;
    }

    constructor(DeployedContracts memory deployedContracts) {
        ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        assetManagementLens = deployedContracts.assetManagementLens.checkAddress();
        ammOpenSwapService = deployedContracts.ammOpenSwapService.checkAddress();
        ammOpenSwapServiceStEth = deployedContracts.ammOpenSwapServiceStEth.checkAddress();
        ammCloseSwapServiceUsdt = deployedContracts.ammCloseSwapServiceUsdt.checkAddress();
        ammCloseSwapServiceUsdc = deployedContracts.ammCloseSwapServiceUsdc.checkAddress();
        ammCloseSwapServiceDai = deployedContracts.ammCloseSwapServiceDai.checkAddress();
        ammCloseSwapServiceStEth = deployedContracts.ammCloseSwapServiceStEth.checkAddress();
        ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        ammPoolsService = deployedContracts.ammPoolsService.checkAddress();
        ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();
        liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();
        powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        flowService = deployedContracts.flowService.checkAddress();
        stakeService = deployedContracts.stakeService.checkAddress();
        ammPoolsServiceStEth = deployedContracts.ammPoolsServiceStEth.checkAddress();
        ammPoolsLensStEth = deployedContracts.ammPoolsLensStEth.checkAddress();
        ammPoolsServiceWeEth = deployedContracts.ammPoolsServiceWeEth.checkAddress();
        ammPoolsLensWeEth = deployedContracts.ammPoolsLensWeEth.checkAddress();
        ammPoolsServiceUsdm = deployedContracts.ammPoolsServiceUsdm.checkAddress();
        ammPoolsLensUsdm = deployedContracts.ammPoolsLensUsdm.checkAddress();

        _disableInitializers();
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContracts struct
    function getConfiguration() external view returns (DeployedContracts memory) {
        return
            DeployedContracts({
                ammSwapsLens: ammSwapsLens,
                ammPoolsLens: ammPoolsLens,
                assetManagementLens: assetManagementLens,
                ammOpenSwapService: ammOpenSwapService,
                ammOpenSwapServiceStEth: ammOpenSwapServiceStEth,
                ammCloseSwapServiceUsdt: ammCloseSwapServiceUsdt,
                ammCloseSwapServiceUsdc: ammCloseSwapServiceUsdc,
                ammCloseSwapServiceDai: ammCloseSwapServiceDai,
                ammCloseSwapLens: ammCloseSwapLens,
                ammCloseSwapServiceStEth: ammCloseSwapServiceStEth,
                ammPoolsService: ammPoolsService,
                ammGovernanceService: ammGovernanceService,
                liquidityMiningLens: liquidityMiningLens,
                powerTokenLens: powerTokenLens,
                flowService: flowService,
                stakeService: stakeService,
                ammPoolsServiceStEth: ammPoolsServiceStEth,
                ammPoolsLensStEth: ammPoolsLensStEth,
                ammPoolsServiceWeEth: ammPoolsServiceWeEth,
                ammPoolsLensWeEth: ammPoolsLensWeEth,
                ammPoolsServiceUsdm: ammPoolsServiceUsdm,
                ammPoolsLensUsdm: ammPoolsLensUsdm
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
            return ammOpenSwapServiceStEth;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed60daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed28daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed90daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed28daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed60daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed90daysUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed28daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed60daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapPayFixed90daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed28daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed60daysUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapService.openSwapReceiveFixed90daysUsdc.selector) ||
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
            return ammOpenSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceStEth.closeSwapsStEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammCloseSwapServiceStEth;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdt.closeSwapsUsdt.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammCloseSwapServiceUsdt;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdc.closeSwapsUsdc.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammCloseSwapServiceUsdc;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceDai.closeSwapsDai.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammCloseSwapServiceDai;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityWEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.redeemFromAmmPoolStEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammPoolsServiceStEth;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.provideLiquidityWeEthToAmmPoolWeEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.provideLiquidity.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.redeemFromAmmPoolWeEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammPoolsServiceWeEth;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.provideLiquidityUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.provideLiquidityUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.provideLiquidityDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.redeemFromAmmPoolUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.redeemFromAmmPoolUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.redeemFromAmmPoolDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsService.rebalanceBetweenAmmTreasuryAndAssetManagement.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammPoolsService;
        }  else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.provideLiquidityUsdmToAmmPoolUsdm.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.redeemFromAmmPoolUsdm.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammPoolsServiceUsdm;
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
            sig == IAmmGovernanceService.setAmmPoolsParams.selector
        ) {
            _onlyOwner();
            return ammGovernanceService;
        } else if (sig == IAmmCloseSwapServiceStEth.emergencyCloseSwapsStEth.selector) {
            _onlyOwner();
            return ammCloseSwapServiceStEth;
        } else if (sig == IAmmCloseSwapServiceUsdt.emergencyCloseSwapsUsdt.selector) {
            _onlyOwner();
            return ammCloseSwapServiceUsdt;
        } else if (sig == IAmmCloseSwapServiceUsdc.emergencyCloseSwapsUsdc.selector) {
            _onlyOwner();
            return ammCloseSwapServiceUsdc;
        } else if (sig == IAmmCloseSwapServiceDai.emergencyCloseSwapsDai.selector) {
            _onlyOwner();
            return ammCloseSwapServiceDai;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector
        ) {
            return ammGovernanceService;
        } else if (sig == IAmmOpenSwapLens.getAmmOpenSwapServicePoolConfiguration.selector) {
            return ammOpenSwapService;
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
            sig == IAmmPoolsLens.getAmmPoolsLensConfiguration.selector ||
            sig == IAmmPoolsLens.getIpTokenExchangeRate.selector ||
            sig == IAmmPoolsLens.getAmmBalance.selector
        ) {
            return ammPoolsLens;
        } else if (
            sig == IAssetManagementLens.balanceOfAmmTreasuryInAssetManagement.selector ||
            sig == IAssetManagementLens.getAssetManagementConfiguration.selector
        ) {
            return assetManagementLens;
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
        } else if (sig == IAmmPoolsLensStEth.getIpstEthExchangeRate.selector) {
            return ammPoolsLensStEth;
        } else if (sig == IAmmPoolsLensWeEth.getIpWeEthExchangeRate.selector) {
            return ammPoolsLensWeEth;
        }  else if (sig == IAmmPoolsLensUsdm.getIpUsdmExchangeRate.selector) {
            return ammPoolsLensUsdm;
        } else if (sig == IAmmPoolsService.getAmmPoolServiceConfiguration.selector) {
            return ammPoolsService;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }
}
