// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@ipor-protocol/contracts/interfaces/IProxyImplementation.sol";
import "@ipor-protocol/contracts/amm/spread/ISpread28Days.sol";
import "@ipor-protocol/contracts/amm/spread/ISpread60Days.sol";
import "@ipor-protocol/contracts/amm/spread/ISpread90Days.sol";
import "@ipor-protocol/contracts/amm/spread/ISpread28DaysLens.sol";
import "@ipor-protocol/contracts/amm/spread/ISpread60DaysLens.sol";
import "@ipor-protocol/contracts/amm/spread/ISpread90DaysLens.sol";
import "@ipor-protocol/contracts/amm/spread/ISpreadStorageLens.sol";
import "@ipor-protocol/contracts/amm/spread/ISpreadCloseSwapService.sol";
import "@ipor-protocol/contracts/amm/spread/SpreadAccessControl.sol";
import "@ipor-protocol/contracts/amm/spread/SpreadStorageLibs.sol";

contract SpreadRouter is UUPSUpgradeable, SpreadAccessControl, IProxyImplementation {
    address internal immutable SPREAD_28_DAYS;
    address internal immutable SPREAD_60_DAYS;
    address internal immutable SPREAD_90_DAYS;
    address internal immutable CLOSE_SWAP_SERVICE;
    address internal immutable STORAGE_LENS;

    struct DeployedContracts {
        address iporProtocolRouter;
        address spread28Days;
        address spread60Days;
        address spread90Days;
        address storageLens;
        address closeSwapService;
    }

    constructor(DeployedContracts memory deployedContracts) SpreadAccessControl(deployedContracts.iporProtocolRouter) {
        require(deployedContracts.spread28Days != address(0), string.concat(IporErrors.WRONG_ADDRESS, " spread28Days"));
        require(deployedContracts.spread60Days != address(0), string.concat(IporErrors.WRONG_ADDRESS, " spread60Days"));
        require(deployedContracts.spread90Days != address(0), string.concat(IporErrors.WRONG_ADDRESS, " spread90Days"));
        require(deployedContracts.storageLens != address(0), string.concat(IporErrors.WRONG_ADDRESS, " storageLens"));
        require(
            deployedContracts.closeSwapService != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " closeSwapService")
        );

        SPREAD_28_DAYS = deployedContracts.spread28Days;
        SPREAD_60_DAYS = deployedContracts.spread60Days;
        SPREAD_90_DAYS = deployedContracts.spread90Days;
        STORAGE_LENS = deployedContracts.storageLens;
        CLOSE_SWAP_SERVICE = deployedContracts.closeSwapService;

        _disableInitializers();
    }

    function initialize(bool paused) public initializer {
        __UUPSUpgradeable_init_unchained();
        SpreadStorageLibs.OwnerStorage storage ownerStorage = SpreadStorageLibs.getOwner();
        ownerStorage.owner = msg.sender;

        if (paused) {
            _pause();
        }
    }

    function getConfiguration() external view returns (DeployedContracts memory deployedContracts) {
        deployedContracts.iporProtocolRouter = IPOR_PROTOCOL_ROUTER;
        deployedContracts.spread28Days = SPREAD_28_DAYS;
        deployedContracts.spread60Days = SPREAD_60_DAYS;
        deployedContracts.spread90Days = SPREAD_90_DAYS;
        deployedContracts.storageLens = STORAGE_LENS;
        deployedContracts.closeSwapService = CLOSE_SWAP_SERVICE;
    }

    function getRouterImplementation(bytes4 sig) public view returns (address) {
        if (
            sig == ISpread28Days.calculateAndUpdateOfferedRatePayFixed28Days.selector ||
            sig == ISpread28Days.calculateAndUpdateOfferedRateReceiveFixed28Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return SPREAD_28_DAYS;
        } else if (
            sig == ISpread60Days.calculateAndUpdateOfferedRatePayFixed60Days.selector ||
            sig == ISpread60Days.calculateAndUpdateOfferedRateReceiveFixed60Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return SPREAD_60_DAYS;
        } else if (
            sig == ISpread90Days.calculateAndUpdateOfferedRatePayFixed90Days.selector ||
            sig == ISpread90Days.calculateAndUpdateOfferedRateReceiveFixed90Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return SPREAD_90_DAYS;
        } else if (
            sig == ISpread28DaysLens.calculateOfferedRatePayFixed28Days.selector ||
            sig == ISpread28DaysLens.calculateOfferedRateReceiveFixed28Days.selector ||
            sig == ISpread28DaysLens.spreadFunction28DaysConfig.selector
        ) {
            return SPREAD_28_DAYS;
        } else if (
            sig == ISpread60DaysLens.calculateOfferedRatePayFixed60Days.selector ||
            sig == ISpread60DaysLens.calculateOfferedRateReceiveFixed60Days.selector ||
            sig == ISpread60DaysLens.spreadFunction60DaysConfig.selector
        ) {
            return SPREAD_60_DAYS;
        } else if (
            sig == ISpread90DaysLens.calculateOfferedRatePayFixed90Days.selector ||
            sig == ISpread90DaysLens.calculateOfferedRateReceiveFixed90Days.selector ||
            sig == ISpread90DaysLens.spreadFunction90DaysConfig.selector
        ) {
            return SPREAD_90_DAYS;
        } else if (sig == ISpreadStorageLens.getTimeWeightedNotional.selector) {
            return STORAGE_LENS;
        } else if (sig == ISpreadCloseSwapService.updateTimeWeightedNotionalOnClose.selector) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return CLOSE_SWAP_SERVICE;
        }
        revert(AmmErrors.FUNCTION_NOT_SUPPORTED);
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _delegate(address implementation) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. This inline assembly block takes thefull control of memory
            // Because it will not return to Solidity code,
            // Solidity scratch pad at memory position 0 is overriden.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 since the size is not know at this point .
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
