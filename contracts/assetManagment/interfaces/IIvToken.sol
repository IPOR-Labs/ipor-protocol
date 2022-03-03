// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIvToken is IERC20 {
    event Mint(address indexed user, uint256 value);

    event Burn(address indexed from, uint256 value);

    event Vault(address setupBy, address vault);

    function mint(address user, uint256 amount) external returns (bool);

    function burn(address user, uint256 amount) external;

    function assetAddress() external view returns (address);
}
