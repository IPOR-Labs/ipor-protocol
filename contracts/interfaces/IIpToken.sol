// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/types/DataTypes.sol";

interface IIpToken is IERC20 {

    event Mint(address indexed user, uint256 value);

    event Burn(address indexed from, address indexed target, uint256 value);

    function mint(
        address user,
        uint256 amount
    ) external returns (bool);

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount
    ) external;

    function getUnderlyingAssetAddress() external view returns (address);
}
