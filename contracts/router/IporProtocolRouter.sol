// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./AccessControl.sol";
import "../libraries/errors/IporErrors.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "../interfaces/IAmmPoolsLens.sol";
import "../interfaces/IAssetManagementLens.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../interfaces/IAmmCloseSwapService.sol";
import "../interfaces/IAmmPoolsService.sol";
import "../interfaces/IAmmGovernanceService.sol";
import "../interfaces/ILiquidityMiningLens.sol";
import "../interfaces/IPowerTokenLens.sol";
import "../interfaces/IPowerTokenFlowsService.sol";
import "../interfaces/IStakeService.sol";

contract IporProtocolRouter is UUPSUpgradeable, AccessControl {
    using Address for address;

    address public immutable AMM_SWAPS_LENS;
    address public immutable AMM_POOLS_LENS;
    address public immutable ASSET_MANAGEMENT_LENS;
    address public immutable AMM_OPEN_SWAP_SERVICE_ADDRESS;
    address public immutable AMM_CLOSE_SWAP_SERVICE_ADDRESS;
    address public immutable AMM_POOLS_SERVICE_ADDRESS;
    address public immutable AMM_GOVERNANCE_SERVICE_ADDRESS;
    address public immutable LIQUIDITY_MINING_LENS_ADDRESS;
    address public immutable POWER_TOKEN_LENS_ADDRESS;
    address public immutable FLOW_SERVICE_ADDRESS;
    address public immutable STAKE_SERVICE_ADDRESS;

    struct DeployedContracts {
        address ammSwapsLens;
        address ammPoolsLens;
        address assetManagementLens;
        address ammOpenSwapService;
        address ammCloseSwapService;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
    }

    constructor(DeployedContracts memory deployedContracts) {
        require(
            deployedContracts.ammSwapsLens != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM_SWAPS_LENS")
        );
        require(
            deployedContracts.ammPoolsLens != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM_POOLS_LENS")
        );
        require(
            deployedContracts.assetManagementLens != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " ASSET_MANAGEMENT_LENS")
        );

        require(
            deployedContracts.ammOpenSwapService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM_OPEN_SWAP_SERVICE_ADDRESS")
        );

        require(
            deployedContracts.ammCloseSwapService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM_CLOSE_SWAP_SERVICE_ADDRESS")
        );

        require(
            deployedContracts.ammPoolsService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM_POOLS_SERVICE_ADDRESS")
        );

        require(
            deployedContracts.ammGovernanceService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " AMM_GOVERNANCE_SERVICE_ADDRESS")
        );

        require(
            deployedContracts.liquidityMiningLens != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " LIQUIDITY_MINING_LENS_ADDRESS")
        );

        require(
            deployedContracts.powerTokenLens != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " POWER_TOKEN_LENS_ADDRESS")
        );

        require(
            deployedContracts.flowService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " FLOW_SERVICE_ADDRESS")
        );

        require(
            deployedContracts.stakeService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " STAKE_SERVICE_ADDRESS")
        );

        AMM_SWAPS_LENS = deployedContracts.ammSwapsLens;
        AMM_POOLS_LENS = deployedContracts.ammPoolsLens;
        ASSET_MANAGEMENT_LENS = deployedContracts.assetManagementLens;
        AMM_OPEN_SWAP_SERVICE_ADDRESS = deployedContracts.ammOpenSwapService;
        AMM_CLOSE_SWAP_SERVICE_ADDRESS = deployedContracts.ammCloseSwapService;
        AMM_POOLS_SERVICE_ADDRESS = deployedContracts.ammPoolsService;
        AMM_GOVERNANCE_SERVICE_ADDRESS = deployedContracts.ammGovernanceService;
        LIQUIDITY_MINING_LENS_ADDRESS = deployedContracts.liquidityMiningLens;
        POWER_TOKEN_LENS_ADDRESS = deployedContracts.powerTokenLens;
        FLOW_SERVICE_ADDRESS = deployedContracts.flowService;
        STAKE_SERVICE_ADDRESS = deployedContracts.stakeService;
        _disableInitializers();
    }

    function getRouterImplementation(bytes4 sig) public returns (address) {
        if (
            sig == IAmmSwapsLens.getSwapsPayFixed.selector ||
            sig == IAmmSwapsLens.getSwapsReceiveFixed.selector ||
            sig == IAmmSwapsLens.getSwaps.selector ||
            sig == IAmmSwapsLens.getPayoffPayFixed.selector ||
            sig == IAmmSwapsLens.getPayoffReceiveFixed.selector ||
            sig == IAmmSwapsLens.getBalancesForOpenSwap.selector ||
            sig == IAmmSwapsLens.getSOAP.selector ||
            sig == IAmmSwapsLens.getAmmSwapsLensConfiguration.selector
        ) {
            return AMM_SWAPS_LENS;
        } else if (
            sig == IAmmPoolsLens.getAmmPoolsLensConfiguration.selector ||
            sig == IAmmPoolsLens.getIpTokenExchangeRate.selector ||
            sig == IAmmPoolsLens.getAmmBalance.selector ||
            sig == IAmmPoolsLens.getLiquidityPoolAccountContribution.selector
        ) {
            return AMM_POOLS_LENS;
        } else if (
            sig == IAssetManagementLens.balanceOfAmmTreasury.selector ||
            sig == IAssetManagementLens.aaveBalanceOf.selector ||
            sig == IAssetManagementLens.compoundBalanceOf.selector ||
            sig == IAssetManagementLens.getIvTokenExchangeRate.selector
        ) {
            return ASSET_MANAGEMENT_LENS;
        } else if (
            sig == ILiquidityMiningLens.getLiquidityMiningContractId.selector ||
            sig == ILiquidityMiningLens.liquidityMiningBalanceOf.selector ||
            sig == ILiquidityMiningLens.balanceOfDelegatedPowerToken.selector ||
            sig == ILiquidityMiningLens.calculateLiquidityMiningAccruedRewards.selector ||
            sig == ILiquidityMiningLens.getLiquidityMiningAccountIndicators.selector ||
            sig == ILiquidityMiningLens.getLiquidityMiningGlobalIndicators.selector ||
            sig == ILiquidityMiningLens.calculateLiquidityMiningAccountRewards.selector
        ) {
            return LIQUIDITY_MINING_LENS_ADDRESS;
        } else if (
            sig == IPowerTokenLens.powerTokenName.selector ||
            sig == IPowerTokenLens.getPowerTokenContractId.selector ||
            sig == IPowerTokenLens.powerTokenSymbol.selector ||
            sig == IPowerTokenLens.powerTokenDecimals.selector ||
            sig == IPowerTokenLens.powerTokenTotalSupply.selector ||
            sig == IPowerTokenLens.powerTokenBalanceOf.selector ||
            sig == IPowerTokenLens.delegatedPowerTokensToLiquidityMiningBalanceOf.selector ||
            sig == IPowerTokenLens.getPowerTokenActiveCooldown.selector ||
            sig == IPowerTokenLens.getUnstakeWithoutCooldownFee.selector ||
            sig == IPowerTokenLens.powerTokenCoolDownTime.selector ||
            sig == IPowerTokenLens.calculatePowerTokenExchangeRate.selector ||
            sig == IPowerTokenLens.totalPowerTokenSupplyBase.selector
        ) {
            return POWER_TOKEN_LENS_ADDRESS;
        } else if (
            sig == IAmmOpenSwapService.openSwapPayFixed28daysUsdt.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed60daysUsdt.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed90daysUsdt.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed28daysUsdt.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed60daysUsdt.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed90daysUsdt.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed28daysUsdc.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed60daysUsdc.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed90daysUsdc.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed28daysUsdc.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed60daysUsdc.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed90daysUsdc.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed28daysDai.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed60daysDai.selector ||
            sig == IAmmOpenSwapService.openSwapPayFixed90daysDai.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed28daysDai.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed60daysDai.selector ||
            sig == IAmmOpenSwapService.openSwapReceiveFixed90daysDai.selector
        ) {
            _whenNotPaused();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_OPEN_SWAP_SERVICE_ADDRESS;
        } else if (
            sig == IAmmCloseSwapService.closeSwapPayFixedUsdt.selector ||
            sig == IAmmCloseSwapService.closeSwapPayFixedUsdc.selector ||
            sig == IAmmCloseSwapService.closeSwapPayFixedDai.selector ||
            sig == IAmmCloseSwapService.closeSwapReceiveFixedUsdt.selector ||
            sig == IAmmCloseSwapService.closeSwapReceiveFixedUsdc.selector ||
            sig == IAmmCloseSwapService.closeSwapReceiveFixedDai.selector ||
            sig == IAmmCloseSwapService.closeSwapsUsdt.selector ||
            sig == IAmmCloseSwapService.closeSwapsUsdc.selector ||
            sig == IAmmCloseSwapService.closeSwapsDai.selector
        ) {
            _whenNotPaused();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_CLOSE_SWAP_SERVICE_ADDRESS;
        } else if (sig == IAmmCloseSwapService.getPoolConfiguration.selector) {
            return AMM_CLOSE_SWAP_SERVICE_ADDRESS;
        } else if (
            sig == IAmmCloseSwapService.emergencyCloseSwapPayFixedUsdt.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapPayFixedUsdc.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapPayFixedDai.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapReceiveFixedUsdt.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapReceiveFixedUsdc.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapReceiveFixedDai.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsPayFixedUsdt.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsPayFixedUsdc.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsPayFixedDai.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsReceiveFixedUsdt.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsReceiveFixedUsdc.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsReceiveFixedDai.selector
        ) {
            _onlyOwner();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_CLOSE_SWAP_SERVICE_ADDRESS;
        } else if (
            sig == IAmmPoolsService.provideLiquidityUsdt.selector ||
            sig == IAmmPoolsService.provideLiquidityUsdc.selector ||
            sig == IAmmPoolsService.provideLiquidityDai.selector ||
            sig == IAmmPoolsService.redeemUsdt.selector ||
            sig == IAmmPoolsService.redeemUsdc.selector ||
            sig == IAmmPoolsService.redeemDai.selector ||
            sig == IAmmPoolsService.rebalance.selector
        ) {
            _whenNotPaused();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_POOLS_SERVICE_ADDRESS;
        } else if (
            sig == IAmmGovernanceService.addSwapLiquidator.selector ||
            sig == IAmmGovernanceService.removeSwapLiquidator.selector ||
            sig == IAmmGovernanceService.setAmmAndAssetManagementRatio.selector ||
            sig == IAmmGovernanceService.setAmmMaxLiquidityPoolBalance.selector ||
            sig == IAmmGovernanceService.setAmmMaxLpAccountContribution.selector ||
            sig == IAmmGovernanceService.addAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.removeAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.setAmmPoolsTreasury.selector ||
            sig == IAmmGovernanceService.setAmmPoolsTreasuryManager.selector ||
            sig == IAmmGovernanceService.setAmmCharlieTreasury.selector ||
            sig == IAmmGovernanceService.setAmmCharlieTreasuryManager.selector ||
            sig == IAmmGovernanceService.setAmmAutoRebalanceThreshold.selector ||
            sig == IAmmGovernanceService.depositToAssetManagement.selector ||
            sig == IAmmGovernanceService.withdrawFromAssetManagement.selector ||
            sig == IAmmGovernanceService.withdrawAllFromAssetManagement.selector
        ) {
            _onlyOwner();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_GOVERNANCE_SERVICE_ADDRESS;
        } else if (
            sig == IAmmGovernanceService.isSwapLiquidator.selector ||
            sig == IAmmGovernanceService.getAmmAndAssetManagementRatio.selector ||
            sig == IAmmGovernanceService.getAmmMaxLiquidityPoolBalance.selector ||
            sig == IAmmGovernanceService.getAmmMaxLpAccountContribution.selector ||
            sig == IAmmGovernanceService.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.getAmmPoolsTreasury.selector ||
            sig == IAmmGovernanceService.getAmmPoolsTreasuryManager.selector ||
            sig == IAmmGovernanceService.getAmmCharlieTreasury.selector ||
            sig == IAmmGovernanceService.getAmmCharlieTreasuryManager.selector ||
            sig == IAmmGovernanceService.getAmmAutoRebalanceThreshold.selector
        ) {
            return AMM_GOVERNANCE_SERVICE_ADDRESS;
        } else if (
            sig == IAmmGovernanceService.transferToTreasury.selector ||
            sig == IAmmGovernanceService.transferToCharlieTreasury.selector
        ) {
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_GOVERNANCE_SERVICE_ADDRESS;
        } else if (
            sig == IPowerTokenStakeService.stakeLpTokensToLiquidityMining.selector ||
            sig == IPowerTokenStakeService.unstakeLpTokensFromLiquidityMining.selector ||
            sig == IPowerTokenStakeService.stakeProtocolToken.selector ||
            sig == IPowerTokenStakeService.unstakeProtocolToken.selector ||
            sig == IPowerTokenStakeService.cooldownPowerToken.selector ||
            sig == IPowerTokenStakeService.cancelPowerTokenCooldown.selector ||
            sig == IPowerTokenStakeService.redeemPowerToken.selector
        ) {
            _whenNotPaused();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return STAKE_SERVICE_ADDRESS;
        } else if (
            sig == IPowerTokenFlowsService.delegateLpTokensToLiquidityMining.selector ||
            sig == IPowerTokenFlowsService.updateLiquidityMiningIndicators.selector ||
            sig == IPowerTokenFlowsService.undelegateLpTokensFromLiquidityMining.selector ||
            sig == IPowerTokenFlowsService.claimPowerToken.selector
        ) {
            _whenNotPaused();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return FLOW_SERVICE_ADDRESS;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }

    fallback() external {
        _delegate(getRouterImplementation(msg.sig));
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _delegate(address implementation) private {
        bytes memory result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())
        }
        //todo: convert into assembly
        if (_reentrancyStatus == _ENTERED) {
            _reentrancyStatus = _NOT_ENTERED;
        }
        assembly {
            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function batchExecutor(bytes[] calldata calls) external {
        uint256 length = calls.length;
        for (uint256 i; i != length; ) {
            bytes4 sig = bytes4(calls[i][:4]);
            address implementation = getRouterImplementation(sig);
            implementation.functionDelegateCall(calls[i]);
            if (_reentrancyStatus == _ENTERED) {
                _reentrancyStatus = _NOT_ENTERED;
            }
            unchecked {
                ++i;
            }
        }
    }

    function initialize(bool paused) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);

        if (paused) {
            _pause();
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
