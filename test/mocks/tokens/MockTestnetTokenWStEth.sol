// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "contracts/amm-eth/interfaces/IStETH.sol";

/// @title Mock of the wstETH token
/// @dev In this mock, for simplicity we don't take into account exchange rate stETH vs wstETH
contract MockTestnetTokenWStEth is ERC20Permit {
    IStETH public stETH;

    /**
     * @param _stETH address of the StETH token to wrap
     */
    constructor(
        IStETH _stETH
    ) public ERC20Permit("Wrapped liquid staked Ether 2.0") ERC20("Wrapped liquid staked Ether 2.0", "wstETH") {
        stETH = _stETH;
    }

    /**
     * @notice Exchanges stETH to wstETH
     * @param _stETHAmount amount of stETH to wrap in exchange for wstETH
     * @dev Requirements:
     *  - `_stETHAmount` must be non-zero
     *  - msg.sender must approve at least `_stETHAmount` stETH to this
     *    contract.
     *  - msg.sender must have at least `_stETHAmount` of stETH.
     * User should first approve _stETHAmount to the WstETH contract
     * @return Amount of wstETH user receives after wrap
     */
    function wrap(uint256 _stETHAmount) external returns (uint256) {
        require(_stETHAmount > 0, "wstETH: can't wrap zero stETH");
        /// @dev in mock, for simplicity we don't take into account exchange rate stETH vs wstETH
        _mint(msg.sender, _stETHAmount);
        stETH.transferFrom(msg.sender, address(this), _stETHAmount);
        return _stETHAmount;
    }

    /**
     * @notice Exchanges wstETH to stETH
     * @param _wstETHAmount amount of wstETH to uwrap in exchange for stETH
     * @dev Requirements:
     *  - `_wstETHAmount` must be non-zero
     *  - msg.sender must have at least `_wstETHAmount` wstETH.
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wstETHAmount) external returns (uint256) {
        require(_wstETHAmount > 0, "wstETH: zero amount unwrap not allowed");
        /// @dev in mock, for simplicity we don't take into account exchange rate stETH vs wstETH
        _burn(msg.sender, _wstETHAmount);
        stETH.transfer(msg.sender, _wstETHAmount);
        return _wstETHAmount;
    }

    /**
     * @notice Shortcut to stake ETH and auto-wrap returned stETH
     */
    receive() external payable {
        uint256 shares = stETH.submit{value: msg.value}(address(0));
        _mint(msg.sender, shares);
    }

    /**
     * @notice Get amount of wstETH for a given amount of stETH
     * @param _stETHAmount amount of stETH
     * @return Amount of wstETH for a given stETH amount
     */
    function getWstETHByStETH(uint256 _stETHAmount) external pure returns (uint256) {
        /// @dev in mock, for simplicity we don't take into account exchange rate stETH vs wstETH
        return _stETHAmount;
    }

    /**
     * @notice Get amount of stETH for a given amount of wstETH
     * @param _wstETHAmount amount of wstETH
     * @return Amount of stETH for a given wstETH amount
     */
    function getStETHByWstETH(uint256 _wstETHAmount) external pure returns (uint256) {
        /// @dev in mock, for simplicity we don't take into account exchange rate stETH vs wstETH
        return _wstETHAmount;
    }

    /**
     * @notice Get amount of stETH for a one wstETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external pure returns (uint256) {
        /// @dev in mock, for simplicity we don't take into account exchange rate stETH vs wstETH
        return 1 ether;
    }

    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of wstETH for a 1 stETH
     */
    function tokensPerStEth() external pure returns (uint256) {
        /// @dev in mock, for simplicity we don't take into account exchange rate stETH vs wstETH
        return 1 ether;
    }
}
