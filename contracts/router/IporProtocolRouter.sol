// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./AccessControl.sol";
import "../libraries/errors/IporErrors.sol";
import "../interfaces/IAmmSwapsLens.sol";
import "../interfaces/IAmmOpenSwapService.sol";
import "../interfaces/IAmmCloseSwapService.sol";
import "../interfaces/IAmmGovernanceService.sol";

contract IporProtocolRouter is UUPSUpgradeable, AccessControl {
    using Address for address;

    address public immutable AMM_SWAPS_LENS;
    address public immutable AMM_OPEN_SWAP_SERVICE_ADDRESS;
    address public immutable AMM_CLOSE_SWAP_SERVICE_ADDRESS;
    address public immutable AMM_GOVERNANCE_SERVICE_ADDRESS;

    struct DeployedContracts {
        address ammSwapsLens;
        address ammOpenSwapServiceAddress;
        address ammCloseSwapServiceAddress;
        address ammGovernanceServiceAddress;
    }

    constructor(DeployedContracts memory deployedContracts) {
        AMM_SWAPS_LENS = deployedContracts.ammSwapsLens;
        AMM_OPEN_SWAP_SERVICE_ADDRESS = deployedContracts.ammOpenSwapServiceAddress;
        AMM_CLOSE_SWAP_SERVICE_ADDRESS = deployedContracts.ammCloseSwapServiceAddress;
        AMM_GOVERNANCE_SERVICE_ADDRESS = deployedContracts.ammGovernanceServiceAddress;
        _disableInitializers();
    }

    function getRouterImplementation(bytes4 sig) public returns (address) {
        if (
            sig == IAmmSwapsLens.getSwapsPayFixed.selector ||
            sig == IAmmSwapsLens.getSwapsReceiveFixed.selector ||
            sig == IAmmSwapsLens.getSwaps.selector
        ) {
            return AMM_SWAPS_LENS;
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
        } else if (sig == IAmmCloseSwapService.closeSwaps.selector) {
            _whenNotPaused();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_CLOSE_SWAP_SERVICE_ADDRESS;
        } else if (
            sig == IAmmGovernanceService.addSwapLiquidator.selector ||
            sig == IAmmGovernanceService.removeSwapLiquidator.selector ||
            sig == IAmmGovernanceService.setAmmPoolsAndAssetManagementRatio.selector ||
            sig == IAmmGovernanceService.setAmmPoolsMaxLiquidityPoolBalance.selector ||
            sig == IAmmGovernanceService.setAmmPoolsMaxLpAccountContribution.selector ||
            sig == IAmmGovernanceService.addAmmPoolsAppointedToRebalance.selector ||
            sig == IAmmGovernanceService.removeAmmPoolsAppointedToRebalance.selector ||
            sig == IAmmGovernanceService.setAmmPoolsTreasury.selector ||
            sig == IAmmGovernanceService.setAmmPoolsTreasuryManager.selector ||
            sig == IAmmGovernanceService.setAmmPoolsCharlieTreasury.selector ||
            sig == IAmmGovernanceService.setAmmPoolsCharlieTreasuryManager.selector ||
            sig == IAmmGovernanceService.setAmmPoolsAutoRebalanceThreshold.selector
        ) {
            _onlyOwner();
            _nonReentrant();
            _reentrancyStatus = _ENTERED;
            return AMM_GOVERNANCE_SERVICE_ADDRESS;
        } else if (
            sig == IAmmGovernanceService.isSwapLiquidator.selector ||
            sig == IAmmGovernanceService.getAmmPoolsAndAssetManagementRatio.selector ||
            sig == IAmmGovernanceService.getAmmPoolsMaxLiquidityPoolBalance.selector ||
            sig == IAmmGovernanceService.getAmmPoolsMaxLpAccountContribution.selector ||
            sig == IAmmGovernanceService.isAmmPoolsAppointedToRebalance.selector ||
            sig == IAmmGovernanceService.getAmmPoolsTreasury.selector ||
            sig == IAmmGovernanceService.getAmmPoolsTreasuryManager.selector ||
            sig == IAmmGovernanceService.getAmmPoolsCharlieTreasury.selector ||
            sig == IAmmGovernanceService.getAmmPoolsCharlieTreasuryManager.selector ||
            sig == IAmmGovernanceService.getAmmPoolsAutoRebalanceThreshold.selector
        ) {
            return AMM_GOVERNANCE_SERVICE_ADDRESS;
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
        //        _owner = msg.sender;

        if (paused) {
            _pause();
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
