// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "./ISpread28Days.sol";
import "./ISpreadLens.sol";
import "./OpenzeppelinStorage.sol";


contract SpreadRouter is OpenzeppelinStorage {

    bytes32 public immutable DAI;
    bytes32 public immutable USDC;
    bytes32 public immutable USDT;
    address public immutable GOVERNANCE;
    address public immutable LENS;
    address public immutable SPREAD_28_DAYS;


    struct DeployedContracts {
        address dai;
        address usdc;
        address usdt;
        address governance;
        address lens;
        address spread28Days;
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


    function initialize(
        bool paused
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        if (paused) {
            _pause();
        }
    }

    function getRouterImplementation(bytes4 sig, bytes32 asset) public view returns (address) {
        if (
            sig == ISpread28Days.calculateQuotePayFixed28Days.selector ||
            sig == ISpread28Days.calculateQuoteReceiveFixed28Days.selector
        ) {
            onlyAmm();
            onlyNotPause();
            return SPREAD_28_DAYS;
        }
        if (
            sig == ISpreadLens.getSupportedAssets.selector ||
            sig == ISpreadLens.getBaseSpreadConfig.selector ||
            sig == ISpreadLens.calculateSpreadPayFixed28Days.selector ||
            sig == ISpreadLens.calculateBaseSpreadPayFixed28Days.selector
        ) {
            nonReentrant();
            return LENS;
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
                return (0, returndatasize())
            }
        }
        if(_status = _ENTERED){
            _status = _NOT_ENTERED;
        }

    }

    fallback() external {
        bytes32 assetBytes = msg.data.length >= 36 ? bytes32(msg.data[4 : 36]) : bytes32(0);
        _delegate(getRouterImplementation(msg.sig, assetBytes));
    }


    /**
 * @notice Function run at the time of the contract upgrade via proxy. Available only to the contract's owner.
     **/
    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}