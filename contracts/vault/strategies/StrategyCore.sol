// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/errors/StanleyErrors.sol";

import "../../security/IporOwnableUpgradeable.sol";
import "../../interfaces/IStrategy.sol";

abstract contract StrategyCore is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IporOwnableUpgradeable,
    PausableUpgradeable,
    IStrategy
{
    address internal _asset;
    address internal _shareToken;
    address internal _stanley;
    address internal _treasury;
    address internal _treasuryManager;

    modifier onlyStanley() {
        require(_msgSender() == _getStanley(), StanleyErrors.CALLER_NOT_STANLEY);
        _;
    }

    modifier onlyTreasuryManager() {
        require(_msgSender() == _getTreasuryManager(), StanleyErrors.CALLER_NOT_TREASURY_MANAGER);
        _;
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    /**
     * @dev Share token to track _asset (DAI -> cDAI)
     */
    function getShareToken() external view override returns (address) {
        return _shareToken;
    }

    function getStanley() external view override returns (address) {
        return _getStanley();
    }

    function setStanley(address newStanley) external whenNotPaused onlyOwner {
        require(newStanley != address(0), IporErrors.WRONG_ADDRESS);
        address oldStanley = _getStanley();
        _stanley = newStanley;
        emit StanleyChanged(_msgSender(), oldStanley, newStanley);
    }

    function setTreasuryManager(address manager) external whenNotPaused onlyOwner {
        require(manager != address(0), IporErrors.WRONG_ADDRESS);
        address oldTreasuryManager = _getTreasuryManager();
        _treasuryManager = manager;
        emit TreasuryManagerChanged(_msgSender(), oldTreasuryManager, manager);
    }

    function setTreasury(address newTreasury) external whenNotPaused onlyTreasuryManager {
        require(newTreasury != address(0), StanleyErrors.INCORRECT_TREASURY_ADDRESS);
        address oldTreasury = _getTreasury();
        _treasury = newTreasury;
        emit TreasuryChanged(_msgSender(), oldTreasury, newTreasury);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getStanley() internal view virtual returns (address) {
        return _stanley;
    }

    function _getTreasury() internal view virtual returns (address) {
        return _treasury;
    }

    function _getTreasuryManager() internal view virtual returns (address) {
        return _treasuryManager;
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
