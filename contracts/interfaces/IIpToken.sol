// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIpToken is IERC20 {
    function getAsset() external view returns (address);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    event Mint(address indexed account, uint256 amount);

    event Burn(address indexed account, uint256 amount);

    event JosephChanged(address changedBy, address newJosephAddress);
}
