// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./AccessControl.sol";
import "../libraries/errors/IporErrors.sol";
import "../interfaces/IAmmSwapsLens.sol";

contract IporProtocolRouter is UUPSUpgradeable, AccessControl {
    address public immutable AMM_SWAPS_LENS;

    using Address for address;

    struct DeployedContracts {
        address ammSwapsLens;
    }

    constructor(DeployedContracts memory deployedContracts) {
        AMM_SWAPS_LENS = deployedContracts.ammSwapsLens;
        _disableInitializers();
    }

    function getRouterImplementation(bytes4 sig) public view returns (address) {
        if (
            sig == IAmmSwapsLens.getSwapsPayFixed.selector ||
            sig == IAmmSwapsLens.getSwapsReceiveFixed.selector ||
            sig == IAmmSwapsLens.getSwaps.selector
        ) {
            return AMM_SWAPS_LENS;
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

    function initialize(uint256 paused) external initializer {
        __UUPSUpgradeable_init();
        _owner = msg.sender;
        _paused = paused;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
