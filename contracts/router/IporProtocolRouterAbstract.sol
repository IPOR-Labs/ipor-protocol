// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IProxyImplementation} from "../interfaces/IProxyImplementation.sol";
import {IporErrors} from "../libraries/errors/IporErrors.sol";
import {IporContractValidator} from "../libraries/IporContractValidator.sol";
import {AccessControl} from "./AccessControl.sol";
import {StorageLibBaseV1} from "../base/libraries/StorageLibBaseV1.sol";
import {OwnerManager} from "../security/OwnerManager.sol";
import {StorageSlotUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";

/// @title Entry point for IPOR protocol
abstract contract IporProtocolRouterAbstract is UUPSUpgradeable, AccessControl, IProxyImplementation {
    using Address for address;
    using IporContractValidator for address;

    uint256 private constant SINGLE_OPERATION = 0;
    uint256 private constant BATCH_OPERATION = 1;

    fallback(bytes calldata input) external payable returns (bytes memory) {
        return _delegate(_getRouterImplementation(msg.sig, SINGLE_OPERATION));
    }

    function initialize(bool pausedInput) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);
        StorageLibBaseV1.getReentrancyStatus().value = _NOT_ENTERED;
    }

    /// @notice Gets the implementation of the router
    /// @return implementation address
    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
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

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal virtual returns (address);

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
            if (StorageLibBaseV1.getReentrancyStatus().value == _ENTERED) {
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
