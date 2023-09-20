//solhint-disable no-empty-blocks
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//IERC20Upgradeable
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../contracts/interfaces/IStrategy.sol";
import "../../contracts/interfaces/IIporContractCommonGov.sol";
import "../../contracts/libraries/math/IporMath.sol";

// simple mock for total _balance tests
contract MockStrategyWithTransfers is IStrategy, IIporContractCommonGov {
    address private _stanley;
    uint256 private _balance;
    uint256 private _apy;
    address private _asset;
    address private _owner;
    address private _treasury;
    address private _treasuryManager;
    bool private _paused;

    modifier notPaused() {
        require(!_paused, "MockStrategyWithTransfers: paused");
        _;
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function deposit(uint256 wadAmount) external override notPaused returns (uint256 depositedAmount) {
        _balance = _balance + wadAmount;

        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, IERC20Metadata(_asset).decimals());
        IERC20Upgradeable(_asset).transferFrom(msg.sender, address(this), amount);

        depositedAmount = IporMath.convertToWad(amount, IERC20Metadata(_asset).decimals());
    }

    function withdraw(uint256 wadAmount) external override notPaused returns (uint256 withdrawnAmount) {
        _balance = _balance - wadAmount;
        uint256 amount = IporMath.convertWadToAssetDecimals(wadAmount, IERC20Metadata(_asset).decimals());
        IERC20Upgradeable(_asset).transfer(msg.sender, amount);
        withdrawnAmount = IporMath.convertToWad(amount, IERC20Metadata(_asset).decimals());
    }

    function asset() external view returns (address) {
        return _asset;
    }

    function shareToken() external view override returns (address) {
        return _asset;
    }

    function isPauseGuardian(address account) external view override returns (bool) {
        return true;
    }

    function addPauseGuardians(address[] calldata guardians) external override {}

    function removePauseGuardians(address[] calldata guardians) external override {}

    function pause() external override {
        _paused = true;
    }

    function unpause() external override {
        _paused = false;
    }

    function setAsset(address asset) external {
        _asset = asset;
    }

    function getApy() external view override returns (uint256) {
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

    function transferOwnership(address newOwner) external {
        _owner = newOwner;
    }
}
