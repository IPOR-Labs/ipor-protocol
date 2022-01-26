// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/types/DataTypes.sol";

interface IIpToken is IERC20 {
    event Mint(address indexed account, uint256 value);

    event Burn(address indexed from, address indexed target, uint256 value);

    function mint(address account, uint256 amount) external;

    function burn(
        address account,
        address receiverOfUnderlying,
        uint256 amount
    ) external;

    function getUnderlyingAssetAddress() external view returns (address);
}
