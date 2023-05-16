// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/IIporAlgorithm.sol";
import "../interfaces/IIporOracle.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";

/// @title MockIporWeighted calculation algorithm.
contract MockIporWeighted is IporOwnableUpgradeable, UUPSUpgradeable, IIporAlgorithm {
    address internal _iporOracleAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address iporOracle) public initializer {
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _iporOracleAddress = iporOracle;
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 1;
    }

    /// @notice return modify ipor index from oracle.
    /// @param asset Asset address
    /// @return iporIndex IPOR index value represented in 18 decimals
    function calculateIpor(address asset) external view returns (uint256 iporIndex) {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        (uint256 value, , ) = IIporOracle(_iporOracleAddress).getIndex(asset);

        return value + 1;
    }

    function setIporOracleAddress(address iporOracleAddress) external onlyOwner {
        _iporOracleAddress = iporOracleAddress;
    }

    function getIporOracleAddress() external view returns (address) {
        return _iporOracleAddress;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}
