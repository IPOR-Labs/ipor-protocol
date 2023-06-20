// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@ipor-protocol/contracts/libraries/errors/IporErrors.sol";
import "@ipor-protocol/contracts/router/AccessControl.sol";
import "@ipor-protocol/contracts/interfaces/IAmmSwapsLens.sol";
import "@ipor-protocol/contracts/interfaces/IAmmPoolsLens.sol";
import "@ipor-protocol/contracts/interfaces/IAssetManagementLens.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenLens.sol";
import "@ipor-protocol/contracts/interfaces/ILiquidityMiningLens.sol";
import "@ipor-protocol/contracts/interfaces/IAmmGovernanceService.sol";
import "@ipor-protocol/contracts/interfaces/IAmmGovernanceLens.sol";
import "@ipor-protocol/contracts/interfaces/IAmmOpenSwapService.sol";
import "@ipor-protocol/contracts/interfaces/IAmmCloseSwapService.sol";
import "@ipor-protocol/contracts/interfaces/IAmmPoolsService.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenFlowsService.sol";
import "@ipor-protocol/contracts/interfaces/IPowerTokenStakeService.sol";
import "@ipor-protocol/contracts/interfaces/IProxyImplementation.sol";

contract IporProtocolRouter is UUPSUpgradeable, AccessControl, IProxyImplementation {
    using Address for address;

    uint256 private constant SINGLE_OPERATION = 0;
    uint256 private constant BATCH_OPERATION = 1;

    address public immutable AMM_SWAPS_LENS;
    address public immutable AMM_POOLS_LENS;
    address public immutable ASSET_MANAGEMENT_LENS;
    address public immutable AMM_OPEN_SWAP_SERVICE;
    address public immutable AMM_CLOSE_SWAP_SERVICE;
    address public immutable AMM_POOLS_SERVICE;
    address public immutable AMM_GOVERNANCE_SERVICE;
    address public immutable LIQUIDITY_MINING_LENS;
    address public immutable POWER_TOKEN_LENS;
    address public immutable FLOW_SERVICE;
    address public immutable STAKE_SERVICE;

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
        AMM_OPEN_SWAP_SERVICE = deployedContracts.ammOpenSwapService;
        AMM_CLOSE_SWAP_SERVICE = deployedContracts.ammCloseSwapService;
        AMM_POOLS_SERVICE = deployedContracts.ammPoolsService;
        AMM_GOVERNANCE_SERVICE = deployedContracts.ammGovernanceService;
        LIQUIDITY_MINING_LENS = deployedContracts.liquidityMiningLens;
        POWER_TOKEN_LENS = deployedContracts.powerTokenLens;
        FLOW_SERVICE = deployedContracts.flowService;
        STAKE_SERVICE = deployedContracts.stakeService;
        _disableInitializers();
    }

    function getRouterImplementation(bytes4 sig, uint256 batchOperation) public returns (address) {
        if (
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
                _nonReentrantBefore;
            }
            return AMM_OPEN_SWAP_SERVICE;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapPayFixedUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapPayFixedUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapPayFixedDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapReceiveFixedUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapReceiveFixedUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapReceiveFixedDai.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapsUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapsUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapsDai.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore;
            }
            return AMM_CLOSE_SWAP_SERVICE;
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
                _nonReentrantBefore;
            }
            return AMM_POOLS_SERVICE;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.stakeLpTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.unstakeLpTokensFromLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.stakeGovernanceTokenToPowerToken.selector) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenStakeService.unstakeGovernanceTokenFromPowerToken.selector
            ) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.pwTokenCooldown.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.pwTokenCancelCooldown.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.redeemPwToken.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore;
            }
            return STAKE_SERVICE;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.delegatePwTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.updateIndicatorsInLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.undelegatePwTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.claimRewardsFromLiquidityMining.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore;
            }
            return FLOW_SERVICE;
        } else if (
            sig == IAmmGovernanceService.transferToTreasury.selector ||
            sig == IAmmGovernanceService.transferToCharlieTreasury.selector
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore;
            }
            return AMM_GOVERNANCE_SERVICE;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore;
            }
            return AMM_GOVERNANCE_SERVICE;
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
            return AMM_GOVERNANCE_SERVICE;
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
            return AMM_CLOSE_SWAP_SERVICE;
        } else if (
            sig == IAmmSwapsLens.getSwaps.selector ||
            sig == IAmmSwapsLens.getPayoffPayFixed.selector ||
            sig == IAmmSwapsLens.getPayoffReceiveFixed.selector ||
            sig == IAmmSwapsLens.getBalancesForOpenSwap.selector ||
            sig == IAmmSwapsLens.getSOAP.selector ||
            sig == IAmmSwapsLens.getAmmSwapsLensConfiguration.selector ||
            sig == IAmmSwapsLens.getOfferedRate.selector
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
            sig == IAssetManagementLens.balanceOfAmmTreasuryInAssetManagement.selector ||
            sig == IAssetManagementLens.balanceOfStrategyAave.selector ||
            sig == IAssetManagementLens.balanceOfStrategyCompound.selector ||
            sig == IAssetManagementLens.getIvTokenExchangeRate.selector
        ) {
            return ASSET_MANAGEMENT_LENS;
        } else if (
            sig == ILiquidityMiningLens.balanceOfLpTokensStakedInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.balanceOfPowerTokensDelegatedToLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccruedRewardsInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getGlobalIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountRewardsInLiquidityMining.selector
        ) {
            return LIQUIDITY_MINING_LENS;
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
            return POWER_TOKEN_LENS;
        } else if (sig == IAmmCloseSwapService.getAmmCloseSwapServicePoolConfiguration.selector) {
            return AMM_CLOSE_SWAP_SERVICE;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }

    fallback() external {
        _delegate(getRouterImplementation(msg.sig, SINGLE_OPERATION));
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
        }
        _nonReentrantAfter();
        assembly {
            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

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

    function batchExecutor(bytes[] calldata calls) external nonReentrant {
        uint256 length = calls.length;
        for (uint256 i; i != length; ) {
            address implementation = getRouterImplementation(bytes4(calls[i][:4]), BATCH_OPERATION);
            implementation.functionDelegateCall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function initialize(bool paused) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);
        StorageLib.getReentrancyStatus().value = _NOT_ENTERED;
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
