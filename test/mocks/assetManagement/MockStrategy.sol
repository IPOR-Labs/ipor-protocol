//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;
import "../../../contracts/interfaces/IStrategy.sol";
import "../../../contracts/interfaces/IStrategyDsr.sol";

// simple mock for total _balance tests
contract MockStrategy is IStrategy, IStrategyDsr {
    address private _assetManagement;
    uint256 private _balance;
    address private _shareTokens;
    uint256 private _apy;
    address private _asset;
    address private _owner;
    address private _treasury;
    address private _treasuryManager;

    constructor(address assetInput, address shareTokensInput) {
        _owner = msg.sender;
        _asset = assetInput;
        _shareTokens = shareTokensInput;
    }

    function getVersion() external pure override returns (uint256) {
        return 2_000;
    }

    function deposit(uint256 amount) external override returns (uint256 depositedAmount) {
        _balance = _balance + amount;
        depositedAmount = amount;
    }

    function withdraw(uint256 amount) external override returns (uint256 withdrawnAmount) {
        _balance = _balance - amount;
        withdrawnAmount = amount;
    }

    function asset() external view returns (address) {
        return _asset;
    }

    function getAsset() external view returns (address) {
        return _asset;
    }

    function pause() external override {}

    function unpause() external override {}

    function isPauseGuardian(address account) external view  returns (bool) {
        return false;
    }

    function addPauseGuardian(address guardian) external  {}

    function removePauseGuardian(address guardian) external  {}

    function setAsset(address asset) external {
        _asset = asset;
    }

    function getApy() external view returns (uint256) {
        return _apy;
    }

    function setApy(uint256 apy) external {
        _apy = apy;
    }

    function balanceOf() external view returns (uint256) {
        return _balance;
    }

    function setBalance(uint256 balance) external {
        _balance = balance;
    }

    function shareToken() external view override returns (address) {
        return _shareTokens;
    }

    function getTreasuryManager() external view override returns (address) {
        return _treasuryManager;
    }

    function setTreasuryManager(address manager) external {
        _treasuryManager = manager;
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function setTreasury(address treasury) external {
        _treasury = treasury;
    }

    function doClaim() external override {}

    function transferOwnership(address newOwner) external {
        _owner = newOwner;
    }

    function beforeClaim() external {}

}
