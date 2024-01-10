// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../interfaces/IAmmSwapsLens.sol";
import "../../../interfaces/IAmmPoolsLens.sol";
import "../../../interfaces/IPowerTokenLens.sol";
import "../../../interfaces/ILiquidityMiningLens.sol";
import "../../../interfaces/IAmmGovernanceService.sol";
import "../../../interfaces/IAmmGovernanceLens.sol";
import "../../../interfaces/IAmmOpenSwapLens.sol";
import "../../../interfaces/IAmmOpenSwapServiceWstEth.sol";
import "../../../interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../interfaces/IAmmCloseSwapLens.sol";
import "../../../interfaces/IPowerTokenFlowsService.sol";
import "../../../interfaces/IPowerTokenStakeService.sol";
import "../../../interfaces/IProxyImplementation.sol";
import "../../../amm-eth/interfaces/IAmmPoolsServiceWstEth.sol";
import "../../../amm-eth/interfaces/IAmmPoolsLensStEth.sol";
import "../../../libraries/errors/IporErrors.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../router/AccessControl.sol";

/// @title Entry point for IPOR protocol
contract IporProtocolRouterArbitrum is UUPSUpgradeable, AccessControl, IProxyImplementation {
    using Address for address;
    using IporContractValidator for address;

    uint256 private constant SINGLE_OPERATION = 0;
    uint256 private constant BATCH_OPERATION = 1;

    address public immutable _ammSwapsLens;
    address public immutable _ammPoolsLens;
    address public immutable _ammOpenSwapService;
    address public immutable _ammOpenSwapServiceWstEth;
    address public immutable _ammCloseSwapServiceWstEth;
    address public immutable _ammCloseSwapLens;
    address public immutable _ammPoolsService;
    address public immutable _ammGovernanceService;
    address public immutable _liquidityMiningLens;
    address public immutable _powerTokenLens;
    address public immutable _flowService;
    address public immutable _stakeService;
    address public immutable _ammPoolsServiceWstEth;
    address public immutable _ammPoolsLensWstEth;

    struct DeployedContractsArbitrum {
        address ammSwapsLens;
        address ammPoolsLens;
        address ammOpenSwapService;
        address ammOpenSwapServiceWstEth;
        address ammCloseSwapServiceWstEth;
        address ammCloseSwapLens;
        address ammPoolsService;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
        address ammPoolsServiceWstEth;
        address ammPoolsLensWstEth;
    }

    constructor(DeployedContractsArbitrum memory deployedContracts) {
        _ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        _ammPoolsLens = deployedContracts.ammPoolsLens.checkAddress();
        _ammOpenSwapService = deployedContracts.ammOpenSwapService.checkAddress();
        _ammOpenSwapServiceWstEth = deployedContracts.ammOpenSwapServiceWstEth.checkAddress();
        _ammCloseSwapServiceWstEth = deployedContracts.ammCloseSwapServiceWstEth.checkAddress();
        _ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        _ammPoolsService = deployedContracts.ammPoolsService.checkAddress();
        _ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();
        _liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();
        _powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        _flowService = deployedContracts.flowService.checkAddress();
        _stakeService = deployedContracts.stakeService.checkAddress();
        _ammPoolsServiceWstEth = deployedContracts.ammPoolsServiceWstEth.checkAddress();
        _ammPoolsLensWstEth = deployedContracts.ammPoolsLensWstEth.checkAddress();
        _disableInitializers();
    }

    fallback(bytes calldata input) external payable returns (bytes memory) {
        return _delegate(_getRouterImplementation(msg.sig, SINGLE_OPERATION));
    }

    function initialize(bool pausedInput) external initializer {
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
    function getConfiguration() external view returns (DeployedContractsArbitrum memory) {
        return
            DeployedContractsArbitrum({
                ammSwapsLens: _ammSwapsLens,
                ammPoolsLens: _ammPoolsLens,
                ammOpenSwapService: _ammOpenSwapService,
                ammOpenSwapServiceWstEth: _ammOpenSwapServiceWstEth,
                ammCloseSwapLens: _ammCloseSwapLens,
                ammCloseSwapServiceWstEth: _ammCloseSwapServiceWstEth,
                ammPoolsService: _ammPoolsService,
                ammGovernanceService: _ammGovernanceService,
                liquidityMiningLens: _liquidityMiningLens,
                powerTokenLens: _powerTokenLens,
                flowService: _flowService,
                stakeService: _stakeService,
                ammPoolsServiceWstEth: _ammPoolsServiceWstEth,
                ammPoolsLensWstEth: _ammPoolsLensWstEth
            });
    }

    /// @notice Allows to execute batch of calls in one transaction using IPOR protocol business methods
    /// @param calls array of encoded calls
    function batchExecutor(bytes[] calldata calls) external payable nonReentrant returns (bytes[] memory) {
        uint256 length = calls.length;
        address implementation;
        bytes[] memory returnData = new bytes[](length);

        for (uint256 i; i != length; ) {
            implementation = _getRouterImplementation(bytes4(calls[i][:4]), BATCH_OPERATION);
            returnData[i] = implementation.functionDelegateCall(calls[i]);
            unchecked {
                ++i;
            }
        }

        _returnBackRemainingEth();

        return returnData;
    }

    receive() external payable {}

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal returns (address) {
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
            return _ammOpenSwapServiceWstEth;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceWstEth.closeSwapsWstEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammCloseSwapServiceWstEth;
        }  else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEth.provideLiquidityWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEth.redeemFromAmmPoolWstEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return _ammPoolsServiceWstEth;
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
        } else if (sig == IAmmCloseSwapServiceWstEth.emergencyCloseSwapsWstEth.selector) {
            _onlyOwner();
            return _ammCloseSwapServiceWstEth;
        }  else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector
        ) {
            return _ammGovernanceService;
        } else if (sig == IAmmOpenSwapLens.getAmmOpenSwapServicePoolConfiguration.selector) {
            return _ammOpenSwapService;
        } else if (
        // TODO: Simplifying the code for the arbitrator
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
        // TODO: This could be removed
            sig == IAmmPoolsLens.getAmmPoolsLensConfiguration.selector ||
            sig == IAmmPoolsLens.getIpTokenExchangeRate.selector ||
        // TODO: Do we need this ?
            sig == IAmmPoolsLens.getAmmBalance.selector
        ) {
            return _ammPoolsLens;
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
        // TODO: remove or convert to wstEth
            sig == IAmmCloseSwapLens.getAmmCloseSwapServicePoolConfiguration.selector ||
            sig == IAmmCloseSwapLens.getClosingSwapDetails.selector
        ) {
            return _ammCloseSwapLens;
        } else if (sig == IAmmPoolsLensStEth.getIpstEthExchangeRate.selector) {
        // TODO: remove or convert to wstEth
            return _ammPoolsLensWstEth;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }

    function _delegate(address implementation) private returns (bytes memory) {
        bytes memory returnData = implementation.functionDelegateCall(msg.data);
        _returnBackRemainingEth();
        _nonReentrantAfter();
        return returnData;
    }

    function _returnBackRemainingEth() private {
        uint256 routerEthBalance = address(this).balance;

        if (routerEthBalance > 0) {
            /// @dev if view method then return back ETH is skipped
            if (StorageLib.getReentrancyStatus().value == _ENTERED) {
                (bool success, ) = msg.sender.call{value: routerEthBalance}("");

                if (!success) {
                    revert(IporErrors.ROUTER_RETURN_BACK_ETH_FAILED);
                }
            }
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
