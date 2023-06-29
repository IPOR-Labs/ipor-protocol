// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../interfaces/IProxyImplementation.sol";
import "../../amm/spread/ISpread28Days.sol";
import "../../amm/spread/ISpread60Days.sol";
import "../../amm/spread/ISpread90Days.sol";
import "../../amm/spread/ISpread28DaysLens.sol";
import "../../amm/spread/ISpread60DaysLens.sol";
import "../../amm/spread/ISpread90DaysLens.sol";
import "../../amm/spread/ISpreadStorageLens.sol";
import "../../amm/spread/ISpreadCloseSwapService.sol";
import "../../amm/spread/SpreadAccessControl.sol";
import "../../amm/spread/SpreadStorageLibs.sol";
import "../../libraries/IporContractValidator.sol";

contract SpreadRouter is UUPSUpgradeable, SpreadAccessControl, IProxyImplementation {
    using IporContractValidator for address;

    address internal immutable _spread28Days;
    address internal immutable _spread60Days;
    address internal immutable _spread90Days;
    address internal immutable _closeSwapService;
    address internal immutable _storageLens;

    struct DeployedContracts {
        address iporProtocolRouter;
        address spread28Days;
        address spread60Days;
        address spread90Days;
        address storageLens;
        address closeSwapService;
    }

    constructor(DeployedContracts memory deployedContracts) SpreadAccessControl(deployedContracts.iporProtocolRouter) {
        _spread28Days = deployedContracts.spread28Days.checkAddress();
        _spread60Days = deployedContracts.spread60Days.checkAddress();
        _spread90Days = deployedContracts.spread90Days.checkAddress();
        _storageLens = deployedContracts.storageLens.checkAddress();
        _closeSwapService = deployedContracts.closeSwapService.checkAddress();

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
        deployedContracts.iporProtocolRouter = _iporProtocolRouter;
        deployedContracts.spread28Days = _spread28Days;
        deployedContracts.spread60Days = _spread60Days;
        deployedContracts.spread90Days = _spread90Days;
        deployedContracts.storageLens = _storageLens;
        deployedContracts.closeSwapService = _closeSwapService;
    }

    function getRouterImplementation(bytes4 sig) public view returns (address) {
        if (
            sig == ISpread28Days.calculateAndUpdateOfferedRatePayFixed28Days.selector ||
            sig == ISpread28Days.calculateAndUpdateOfferedRateReceiveFixed28Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _spread28Days;
        } else if (
            sig == ISpread60Days.calculateAndUpdateOfferedRatePayFixed60Days.selector ||
            sig == ISpread60Days.calculateAndUpdateOfferedRateReceiveFixed60Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _spread60Days;
        } else if (
            sig == ISpread90Days.calculateAndUpdateOfferedRatePayFixed90Days.selector ||
            sig == ISpread90Days.calculateAndUpdateOfferedRateReceiveFixed90Days.selector
        ) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _spread90Days;
        } else if (
            sig == ISpread28DaysLens.calculateOfferedRatePayFixed28Days.selector ||
            sig == ISpread28DaysLens.calculateOfferedRateReceiveFixed28Days.selector ||
            sig == ISpread28DaysLens.spreadFunction28DaysConfig.selector
        ) {
            return _spread28Days;
        } else if (
            sig == ISpread60DaysLens.calculateOfferedRatePayFixed60Days.selector ||
            sig == ISpread60DaysLens.calculateOfferedRateReceiveFixed60Days.selector ||
            sig == ISpread60DaysLens.spreadFunction60DaysConfig.selector
        ) {
            return _spread60Days;
        } else if (
            sig == ISpread90DaysLens.calculateOfferedRatePayFixed90Days.selector ||
            sig == ISpread90DaysLens.calculateOfferedRateReceiveFixed90Days.selector ||
            sig == ISpread90DaysLens.spreadFunction90DaysConfig.selector
        ) {
            return _spread90Days;
        } else if (sig == ISpreadStorageLens.getTimeWeightedNotional.selector) {
            return _storageLens;
        } else if (sig == ISpreadCloseSwapService.updateTimeWeightedNotionalOnClose.selector) {
            _onlyIporProtocolRouter();
            _whenNotPaused();
            return _closeSwapService;
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
