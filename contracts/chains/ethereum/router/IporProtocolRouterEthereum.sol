// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

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
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../router/IporProtocolRouterAbstract.sol";
import "../../../amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import "../../../base/interfaces/IAmmGovernanceServiceBaseV1.sol";

import "../../../base/libraries/StorageLibBaseV1.sol";

/// @title Entry point for IPOR protocol on Ethereum chain
contract IporProtocolRouterEthereum is IporProtocolRouterAbstract {
    using IporContractValidator for address;

    address public immutable ammSwapsLens;
    /// @dev for USDT, USDC, DAI pools
    address public immutable ammPoolsLens;
    /// @dev USDM, weETH, stETH pools
    address public immutable ammPoolsLensBaseV1;
    address public immutable ammCloseSwapLens;
    address public immutable ammGovernanceService;

    address public immutable flowService;
    address public immutable stakeService;
    address public immutable powerTokenLens;
    address public immutable liquidityMiningLens;

    address public immutable ammCloseSwapServiceUsdt;
    address public immutable ammCloseSwapServiceUsdc;
    address public immutable ammCloseSwapServiceDai;
    /// @dev for USDT, USDC, DAI pools
    address public immutable ammOpenSwapService;
    /// @dev for USDT, USDC, DAI pools
    address public immutable ammPoolsService;
    /// @dev for USDT, USDC, DAI pools
    address public immutable assetManagementLens;

    address public immutable stEth;
    address public immutable weEth;
    address public immutable usdm;

    struct DeployedContracts {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammPoolsLensBaseV1;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapServiceUsdt;
        address ammCloseSwapServiceUsdc;
        address ammCloseSwapServiceDai;
        address ammCloseSwapLens;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
        address ammPoolsServiceWeEth;
        address ammPoolsLensWeEth;
        address ammPoolsServiceUsdm;
        address ammPoolsLensUsdm;
        address stEth;
        address weEth;
        address usdm;
    }

    constructor(DeployedContracts memory deployedContracts) {
        ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        ammPoolsLensBaseV1 = deployedContracts.ammPoolsLensBaseV1.checkAddress();
        ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();

        flowService = deployedContracts.flowService.checkAddress();
        stakeService = deployedContracts.stakeService.checkAddress();
        powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();

        assetManagementLens = deployedContracts.assetManagementLens.checkAddress();
        ammOpenSwapService = deployedContracts.ammOpenSwapService.checkAddress();
        ammCloseSwapServiceUsdt = deployedContracts.ammCloseSwapServiceUsdt.checkAddress();
        ammCloseSwapServiceUsdc = deployedContracts.ammCloseSwapServiceUsdc.checkAddress();
        ammCloseSwapServiceDai = deployedContracts.ammCloseSwapServiceDai.checkAddress();
        ammPoolsService = deployedContracts.ammPoolsService.checkAddress();

        stEth = deployedContracts.stEth.checkAddress();
        weEth = deployedContracts.weEth.checkAddress();
        usdm = deployedContracts.usdm.checkAddress();

        _disableInitializers();
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContracts struct
    function getConfiguration() external view returns (DeployedContracts memory) {
        return
            DeployedContracts({
                ammSwapsLens: ammSwapsLens,
                ammPoolsLens: ammPoolsLens,
                ammPoolsLensBaseV1: ammPoolsLensBaseV1,
                ammCloseSwapLens: ammCloseSwapLens,
                ammGovernanceService: ammGovernanceService,
                flowService: flowService,
                stakeService: stakeService,
                powerTokenLens: powerTokenLens,
                liquidityMiningLens: liquidityMiningLens,
                ammCloseSwapServiceUsdt: ammCloseSwapServiceUsdt,
                ammCloseSwapServiceUsdc: ammCloseSwapServiceUsdc,
                ammCloseSwapServiceDai: ammCloseSwapServiceDai,
                ammOpenSwapService: ammOpenSwapService,
                ammPoolsService: ammPoolsService,
                assetManagementLens: assetManagementLens,
                ammPoolsServiceWeEth: address(0),
                ammPoolsLensWeEth: address(0),
                ammPoolsServiceUsdm: address(0),
                ammPoolsLensUsdm: address(0),
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
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
                stEth
            ];
            return servicesCfg.ammOpenSwapService;
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
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
                stEth
            ];
            return servicesCfg.ammCloseSwapService;
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
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
                stEth
            ];
            return servicesCfg.ammPoolsService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.provideLiquidityWeEthToAmmPoolWeEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.provideLiquidity.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWeEth.redeemFromAmmPoolWeEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
                weEth
            ];
            return servicesCfg.ammPoolsService;
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
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.provideLiquidityUsdmToAmmPoolUsdm.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceUsdm.redeemFromAmmPoolUsdm.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
                        usdm
                ];
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
            sig == IAmmGovernanceServiceBaseV1.setMessageSigner.selector ||
            sig == IAmmGovernanceServiceBaseV1.setAssetLensData.selector ||
            sig == IAmmGovernanceServiceBaseV1.setAmmGovernancePoolConfiguration.selector ||
            sig == IAmmGovernanceServiceBaseV1.setAssetServices.selector
        ) {
            _onlyOwner();
            return ammGovernanceService;
        } else if (sig == IAmmCloseSwapServiceStEth.emergencyCloseSwapsStEth.selector) {
            _onlyOwner();
            StorageLibBaseV1.AssetServicesValue storage servicesCfg = StorageLibBaseV1.getAssetServicesStorage().value[
                stEth
            ];
            return servicesCfg.ammCloseSwapService;
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
            sig == IAmmPoolsLens.getAmmPoolsLensConfiguration.selector || sig == IAmmPoolsLens.getAmmBalance.selector
        ) {
            return ammPoolsLens;
        } else if (sig == IAmmPoolsLens.getIpTokenExchangeRate.selector) {
            // Extract asset address from calldata (first parameter after selector)
            address asset;
            assembly {
                asset := calldataload(4)
            }

            // Check if asset uses new BaseV1 architecture (stETH, weETH, USDM)
            if (asset == stEth || asset == weEth || asset == usdm) {
                return ammPoolsLensBaseV1;
            } else {
                // For legacy assets (USDT, USDC, DAI)
                return ammPoolsLens;
            }
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
        } else if (sig == IAmmPoolsService.getAmmPoolServiceConfiguration.selector) {
            return ammPoolsService;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }
}
