// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/IporOracleErrors.sol";
import "../interfaces/IIporOracle.sol";
import "../interfaces/IIporRiskManagementOracle.sol";
import "../interfaces/IOraclePublisher.sol";
import "../interfaces/IProxyImplementation.sol";
import "../security/IporOwnableUpgradeable.sol";

/**
 * @title IPOR Oracle Publisher contract
 *
 * @author IPOR Labs
 */
contract OraclePublisher is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IporOwnableUpgradeable,
    IOraclePublisher,
    IProxyImplementation
{
    using Address for address;

    address internal immutable _iporOracle;
    address internal immutable _iporRiskManagementOracle;

    mapping(address => uint256) internal _updaters;

    modifier onlyUpdater() {
        require(_updaters[_msgSender()] == 1, IporOracleErrors.CALLER_NOT_UPDATER);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporOracle, address iporRiskManagementOracle) {
        require(iporOracle != address(0), string.concat(IporErrors.WRONG_ADDRESS, " IporOracle"));
        require(
            iporRiskManagementOracle != address(0),
            string.concat(IporErrors.WRONG_ADDRESS, " IporRiskManagementOracle")
        );
        _disableInitializers();

        _iporOracle = iporOracle;
        _iporRiskManagementOracle = iporRiskManagementOracle;
    }

    function initialize() public initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 2_000;
    }

    function getConfiguration() external view returns (address iporOracle, address iporRiskManagementOracle) {
        return (address(_iporOracle), address(_iporRiskManagementOracle));
    }

    function publish(address[] memory addresses, bytes[] calldata calls) external override onlyUpdater whenNotPaused {
        uint256 addressesLength = addresses.length;
        require(addressesLength == calls.length, IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH);
        for (uint256 i = 0; i < addressesLength; i++) {
            require(
                addresses[i] == _iporOracle || addresses[i] == _iporRiskManagementOracle,
                IporOracleErrors.INVALID_ORACLE_ADDRESS
            );
            addresses[i].functionCall(calls[i]);
        }
    }

    function addUpdater(address updater) external override onlyOwner {
        _updaters[updater] = 1;
        emit OraclePublisherUpdaterAdded(updater);
    }

    function removeUpdater(address updater) external override onlyOwner {
        _updaters[updater] = 0;
        emit OraclePublisherUpdaterRemoved(updater);
    }

    function isUpdater(address updater) external view override returns (uint256) {
        return _updaters[updater];
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
