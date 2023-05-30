// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "contracts/security/IporOwnableUpgradeable.sol";
import "contracts/interfaces/types/IporOracleTypes.sol";

/// @dev for testing purposes
contract EmptyIporOracleImplementation is Initializable, PausableUpgradeable, UUPSUpgradeable, IporOwnableUpgradeable {
    mapping(address => uint256) internal _updaters;
    mapping(address => IporOracleTypes.IPOR) internal _indexes;

    function initialize(address[] memory assets, uint32[] memory updateTimestamps) external initializer {
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __UUPSUpgradeable_init_unchained();

        uint256 assetsLength = assets.length;

        for (uint256 i; i != assetsLength; ++i) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);

            _indexes[assets[i]] = IporOracleTypes.IPOR(0, 0, updateTimestamps[i]);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
