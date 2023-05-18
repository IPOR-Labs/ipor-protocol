// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "forge-std/console2.sol";
import "./ISpread28Days.sol";
import "./ISpread60Days.sol";
import "./ISpread90Days.sol";
import "./ISpread28DaysLens.sol";
import "./OpenzeppelinStorage.sol";

contract SpreadRouter is UUPSUpgradeable {
    bytes32 internal immutable DAI;
    bytes32 internal immutable USDC;
    bytes32 internal immutable USDT;
    address internal immutable SPREAD_28_DAYS;
    address internal immutable SPREAD_60_DAYS;
    address internal immutable SPREAD_90_DAYS;
    address internal immutable AMM_ADDRESS;
    address internal immutable STORAGE_LENS;

    struct DeployedContracts {
        address ammAddress;
        address dai;
        address usdc;
        address usdt;
        address lens;
        address spread28Days;
        address spread60Days;
        address spread90Days;
        address storageLens;
    }

    constructor(DeployedContracts memory deployedContracts) {
        GOVERNANCE = deployedContracts.governance;
        LENS = deployedContracts.lens;
        SPREAD_28_DAYS = deployedContracts.spread28Days;
        DAI = bytes32(uint256(uint160(deployedContracts.dai)));
        USDC = bytes32(uint256(uint160(deployedContracts.usdc)));
        USDT = bytes32(uint256(uint160(deployedContracts.usdt)));

        _disableInitializers();
    }

    function initialize(bool paused) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        if (paused) {
            _pause();
        }
    }

    function getRouterImplementation(bytes4 sig) public view returns (address) {
        if (
            sig == ISpread28Days.calculateQuotePayFixed28Days.selector ||
            sig == ISpread28Days.calculateQuoteReceiveFixed28Days.selector
        ) {
            //            onlyAmm();
            //            onlyNotPause();
            return SPREAD_28_DAYS;
        } else if (
            sig == ISpread60Days.calculateQuotePayFixed60Days.selector ||
            sig == ISpread60Days.calculateQuoteReceiveFixed60Days.selector
        ) {
            //            onlyAmm();
            //            onlyNotPause();
            return SPREAD_60_DAYS;
        } else if (
            sig == ISpread90Days.calculateQuotePayFixed90Days.selector ||
            sig == ISpread90Days.calculateQuoteReceiveFixed90Days.selector
        ) {
            //            onlyAmm();
            //            onlyNotPause();
            return SPREAD_90_DAYS;
        } else if (
            sig == ISpread28DaysLens.calculatePayFixed28Days.selector ||
            sig == ISpread28DaysLens.calculateReceiveFixed28Days.selector
        ) {
            return SPREAD_28_DAYS;
        } else if (
            sig == ISpread60DaysLens.calculatePayFixed60Days.selector ||
            sig == ISpread60DaysLens.calculateReceiveFixed60Days.selector
        ) {
            return SPREAD_60_DAYS;
        } else if (
            sig == ISpread90DaysLens.calculatePayFixed90Days.selector ||
            sig == ISpread90DaysLens.calculateReceiveFixed90Days.selector
        ) {
            return SPREAD_90_DAYS;
        }
        return address(0);
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _delegate(address implementation) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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
        //        if(_status = _ENTERED){
        //            _status = _NOT_ENTERED;
        //        }
    }

    fallback() external {
        _delegate(getRouterImplementation(msg.sig));
    }

    /**
     * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
