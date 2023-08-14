// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IAmmSwapsLens.sol";
import "../interfaces/IAmmPoolsLens.sol";
import "../interfaces/IAssetManagementLens.sol";
import "../interfaces/IPowerTokenLens.sol";
import "../interfaces/ILiquidityMiningLens.sol";
import "../interfaces/IAmmGovernanceService.sol";
import "../interfaces/IAmmGovernanceLens.sol";
import "../interfaces/IAmmOpenSwapLens.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../interfaces/IAmmCloseSwapService.sol";
import "../interfaces/IAmmCloseSwapLens.sol";
import "../interfaces/IAmmPoolsService.sol";
import "../interfaces/IPowerTokenFlowsService.sol";
import "../interfaces/IPowerTokenStakeService.sol";
import "../interfaces/IProxyImplementation.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "./AccessControl.sol";
import "../ethMarket/IAmmPoolsLensEth.sol";
import "../ethMarket/IAmmPoolsServiceEth.sol";

/// @title Entry point for IPOR protocol
contract IporProtocolRouter is UUPSUpgradeable, AccessControl, IProxyImplementation {
    using Address for address;
    using IporContractValidator for address;

    uint256 private constant SINGLE_OPERATION = 0;
    uint256 private constant BATCH_OPERATION = 1;

    address public immutable _ammSwapsLens;
    address public immutable _ammPoolsLens;
    address public immutable _ammManagementLens;
    address public immutable _ammOpenSwapService;
    address public immutable _ammCloseSwapService;
    address public immutable _ammPoolsService;
    address public immutable _ammGovernanceService;
    address public immutable _liquidityMiningLens;
    address public immutable _powerTokenLens;
    address public immutable _flowService;
    address public immutable _stakeService;
    address public immutable _ammPoolsServiceEth;
    address public immutable _ammPoolsLensEth;

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
        address ammPoolsServiceEth;
        address ammPoolsLensEth;
    }

    constructor(DeployedContracts memory deployedContracts) {
        _ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        _ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        _ammManagementLens = deployedContracts.assetManagementLens.checkAddress();
        _ammOpenSwapService = deployedContracts.ammOpenSwapService.checkAddress();
        _ammCloseSwapService = deployedContracts.ammCloseSwapService.checkAddress();
        _ammPoolsService = deployedContracts.ammPoolsService.checkAddress();
        _ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();
        _liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();
        _powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        _flowService = deployedContracts.flowService.checkAddress();
        _stakeService = deployedContracts.stakeService.checkAddress();
        _ammPoolsServiceEth = deployedContracts.ammPoolsServiceEth.checkAddress();
        _ammPoolsLensEth = deployedContracts.ammPoolsLensEth.checkAddress();
        _disableInitializers();
    }

    fallback() external payable {
        _delegate(_getRouterImplementation(msg.sig, SINGLE_OPERATION));
    }

    receive() external payable {}

    function initialize(bool paused) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);
        StorageLib.getReentrancyStatus().value = _NOT_ENTERED;
    }

    /// @notice Gets the implementation of the router
    /// @return implementation address
    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContracts struct
    function getConfiguration() external view returns (DeployedContracts memory) {
        return
            DeployedContracts({
                ammSwapsLens: _ammSwapsLens,
                ammPoolsLens: _ammPoolsLens,
                assetManagementLens: _ammManagementLens,
                ammOpenSwapService: _ammOpenSwapService,
                ammCloseSwapService: _ammCloseSwapService,
                ammPoolsService: _ammPoolsService,
                ammGovernanceService: _ammGovernanceService,
                liquidityMiningLens: _liquidityMiningLens,
                powerTokenLens: _powerTokenLens,
                flowService: _flowService,
                stakeService: _stakeService,
                ammPoolsServiceEth: _ammPoolsServiceEth,
                ammPoolsLensEth: _ammPoolsLensEth
            });
    }

    /// @notice Allows to execute batch of calls in one transaction using IPOR protocol business methods
    /// @param calls array of encoded calls
    function batchExecutor(bytes[] calldata calls) external payable nonReentrant {
        uint256 length = calls.length;
        address implementation;

        for (uint256 i; i != length; ) {
            implementation = _getRouterImplementation(bytes4(calls[i][:4]), BATCH_OPERATION);
            implementation.functionDelegateCall(calls[i]);
            unchecked {
                ++i;
            }
        }
        uint256 remainingGas = address(this).balance;
        if(remainingGas > 0) {
            payable(msg.sender).transfer(remainingGas);
        }
    }

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal returns (address) {
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
                _nonReentrantBefore();
            }
            return _ammOpenSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapsUsdt.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapsUsdc.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapService.closeSwapsDai.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammCloseSwapService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceEth.provideLiquidityStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceEth.provideLiquidityWEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceEth.provideLiquidityEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceEth.redeemFromAmmPoolStEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammPoolsServiceEth;
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
            return _ammPoolsService;
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
            return _stakeService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.delegatePwTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.updateIndicatorsInLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.undelegatePwTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.claimRewardsFromLiquidityMining.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _flowService;
        } else if (
            sig == IAmmGovernanceService.transferToTreasury.selector ||
            sig == IAmmGovernanceService.transferToCharlieTreasury.selector
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammGovernanceService;
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
            return _ammGovernanceService;
        } else if (
            sig == IAmmCloseSwapService.emergencyCloseSwapsUsdt.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsUsdc.selector ||
            sig == IAmmCloseSwapService.emergencyCloseSwapsDai.selector
        ) {
            _onlyOwner();
            return _ammCloseSwapService;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector
        ) {
            return _ammGovernanceService;
        } else if (sig == IAmmOpenSwapLens.getAmmOpenSwapServicePoolConfiguration.selector) {
            return _ammOpenSwapService;
        } else if (
            sig == IAmmSwapsLens.getSwaps.selector ||
            sig == IAmmSwapsLens.getPnlPayFixed.selector ||
            sig == IAmmSwapsLens.getPnlReceiveFixed.selector ||
            sig == IAmmSwapsLens.getBalancesForOpenSwap.selector ||
            sig == IAmmSwapsLens.getSoap.selector ||
            sig == IAmmSwapsLens.getOpenSwapRiskIndicators.selector ||
            sig == IAmmSwapsLens.getOfferedRate.selector
        ) {
            return _ammSwapsLens;
        } else if (
            sig == IAmmPoolsLens.getAmmPoolsLensConfiguration.selector ||
            sig == IAmmPoolsLens.getIpTokenExchangeRate.selector ||
            sig == IAmmPoolsLens.getAmmBalance.selector
        ) {
            return _ammPoolsLens;
        } else if (
            sig == IAssetManagementLens.balanceOfAmmTreasuryInAssetManagement.selector ||
            sig == IAssetManagementLens.balanceOfStrategyAave.selector ||
            sig == IAssetManagementLens.balanceOfStrategyCompound.selector ||
            sig == IAssetManagementLens.getIvTokenExchangeRate.selector
        ) {
            return _ammManagementLens;
        } else if (
            sig == ILiquidityMiningLens.balanceOfLpTokensStakedInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.balanceOfPowerTokensDelegatedToLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccruedRewardsInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getGlobalIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountRewardsInLiquidityMining.selector
        ) {
            return _liquidityMiningLens;
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
            return _powerTokenLens;
        } else if (
            sig == IAmmCloseSwapLens.getAmmCloseSwapServicePoolConfiguration.selector ||
            sig == IAmmCloseSwapLens.getClosingSwapDetails.selector
        ) {
            return _ammCloseSwapService;
        } else if (sig == IAmmPoolsLensEth.getIpstEthExchangeRate.selector) {
            return _ammPoolsLensEth;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
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
        uint256 remainingGas = address(this).balance;
        if(remainingGas > 0) {
            payable(msg.sender).transfer(remainingGas);
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

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
