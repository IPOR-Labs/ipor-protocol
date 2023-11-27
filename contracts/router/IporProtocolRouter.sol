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
import "../interfaces/IAmmOpenSwapServiceStEth.sol";
import "../interfaces/IAmmCloseSwapServiceUsdt.sol";
import "../interfaces/IAmmCloseSwapServiceUsdc.sol";
import "../interfaces/IAmmCloseSwapServiceDai.sol";
import "../interfaces/IAmmCloseSwapServiceStEth.sol";
import "../interfaces/IAmmCloseSwapLens.sol";
import "../interfaces/IAmmPoolsService.sol";
import "../interfaces/IPowerTokenFlowsService.sol";
import "../interfaces/IPowerTokenStakeService.sol";
import "../interfaces/IProxyImplementation.sol";
import "../amm-eth/interfaces/IAmmPoolsServiceStEth.sol";
import "../amm-eth/interfaces/IAmmPoolsLensStEth.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/IporContractValidator.sol";
import "./AccessControl.sol";

/// @title Entry point for IPOR protocol
contract IporProtocolRouter is UUPSUpgradeable, AccessControl, IProxyImplementation {
    using Address for address;
    using IporContractValidator for address;

    uint256 private constant SINGLE_OPERATION = 0;
    uint256 private constant BATCH_OPERATION = 1;

    address public immutable _ammSwapsLens;
    address public immutable _ammPoolsLens;
    address public immutable _assetManagementLens;
    address public immutable _ammOpenSwapService;
    address public immutable _ammOpenSwapServiceStEth;
    address public immutable _ammCloseSwapServiceUsdt;
    address public immutable _ammCloseSwapServiceUsdc;
    address public immutable _ammCloseSwapServiceDai;
    address public immutable _ammCloseSwapServiceStEth;
    address public immutable _ammCloseSwapLens;
    address public immutable _ammPoolsService;
    address public immutable _ammGovernanceService;
    address public immutable _liquidityMiningLens;
    address public immutable _powerTokenLens;
    address public immutable _flowService;
    address public immutable _stakeService;
    address public immutable _ammPoolsServiceStEth;
    address public immutable _ammPoolsLensStEth;

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
    }

    constructor(DeployedContracts memory deployedContracts) {
        _ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        _ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        _assetManagementLens = deployedContracts.assetManagementLens.checkAddress();
        _ammOpenSwapService = deployedContracts.ammOpenSwapService.checkAddress();
        _ammOpenSwapServiceStEth = deployedContracts.ammOpenSwapServiceStEth.checkAddress();
        _ammCloseSwapServiceUsdt = deployedContracts.ammCloseSwapServiceUsdt.checkAddress();
        _ammCloseSwapServiceUsdc = deployedContracts.ammCloseSwapServiceUsdc.checkAddress();
        _ammCloseSwapServiceDai = deployedContracts.ammCloseSwapServiceDai.checkAddress();
        _ammCloseSwapServiceStEth = deployedContracts.ammCloseSwapServiceStEth.checkAddress();
        _ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        _ammPoolsService = deployedContracts.ammPoolsService.checkAddress();
        _ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();
        _liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();
        _powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        _flowService = deployedContracts.flowService.checkAddress();
        _stakeService = deployedContracts.stakeService.checkAddress();
        _ammPoolsServiceStEth = deployedContracts.ammPoolsServiceStEth.checkAddress();
        _ammPoolsLensStEth = deployedContracts.ammPoolsLensStEth.checkAddress();
        _disableInitializers();
    }

    fallback() external payable {
        _delegate(_getRouterImplementation(msg.sig, SINGLE_OPERATION));
    }

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
                assetManagementLens: _assetManagementLens,
                ammOpenSwapService: _ammOpenSwapService,
                ammOpenSwapServiceStEth: _ammOpenSwapServiceStEth,
                ammCloseSwapServiceUsdt: _ammCloseSwapServiceUsdt,
                ammCloseSwapServiceUsdc: _ammCloseSwapServiceUsdc,
                ammCloseSwapServiceDai: _ammCloseSwapServiceDai,
                ammCloseSwapLens: _ammCloseSwapLens,
                ammCloseSwapServiceStEth: _ammCloseSwapServiceStEth,
                ammPoolsService: _ammPoolsService,
                ammGovernanceService: _ammGovernanceService,
                liquidityMiningLens: _liquidityMiningLens,
                powerTokenLens: _powerTokenLens,
                flowService: _flowService,
                stakeService: _stakeService,
                ammPoolsServiceStEth: _ammPoolsServiceStEth,
                ammPoolsLensStEth: _ammPoolsLensStEth
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

        _returnBackRemainingEth();
    }

    receive() external payable {}

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal returns (address) {
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
            return _ammOpenSwapServiceStEth;
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
            return _ammOpenSwapService;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceStEth.closeSwapsStEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammCloseSwapServiceStEth;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdt.closeSwapsUsdt.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammCloseSwapServiceUsdt;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceUsdc.closeSwapsUsdc.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammCloseSwapServiceUsdc;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceDai.closeSwapsDai.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammCloseSwapServiceDai;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityStEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityWEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.provideLiquidityEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceStEth.redeemFromAmmPoolStEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammPoolsServiceStEth;
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
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenFlowsService.undelegatePwTokensFromLiquidityMining.selector
            ) ||
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
        } else if (sig == IAmmCloseSwapServiceStEth.emergencyCloseSwapsStEth.selector) {
            _onlyOwner();
            return _ammCloseSwapServiceStEth;
        } else if (sig == IAmmCloseSwapServiceUsdt.emergencyCloseSwapsUsdt.selector) {
            _onlyOwner();
            return _ammCloseSwapServiceUsdt;
        } else if (sig == IAmmCloseSwapServiceUsdc.emergencyCloseSwapsUsdc.selector) {
            _onlyOwner();
            return _ammCloseSwapServiceUsdc;
        } else if (sig == IAmmCloseSwapServiceDai.emergencyCloseSwapsDai.selector) {
            _onlyOwner();
            return _ammCloseSwapServiceDai;
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
            sig == IAmmSwapsLens.getOfferedRate.selector ||
            sig == IAmmSwapsLens.getSwapLensPoolConfiguration.selector
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
            sig == IAssetManagementLens.getAssetManagementConfiguration.selector
        ) {
            return _assetManagementLens;
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
            return _ammCloseSwapLens;
        } else if (sig == IAmmPoolsLensStEth.getIpstEthExchangeRate.selector) {
            return _ammPoolsLensStEth;
        } else if (sig == IAmmPoolsService.getAmmPoolServiceConfiguration.selector) {
            return _ammPoolsService;
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

        _returnBackRemainingEth();
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

    function _returnBackRemainingEth() private {
        uint256 routerEthBalance = address(this).balance;

        if (routerEthBalance > 0) {
            (bool success, ) = msg.sender.call{value: routerEthBalance}("");

            if (!success) {
                revert(IporErrors.ROUTER_RETURN_BACK_ETH_FAILED);
            }
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
