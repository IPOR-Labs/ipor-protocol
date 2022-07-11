// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/errors/JosephErrors.sol";
import "../security/IporOwnable.sol";

contract IporToken is IporOwnable, ERC20 {
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        address daoWalletAddress
    ) ERC20(name, symbol) {
        _decimals = 18;
        _mint(daoWalletAddress, 100_000_000 * 1e18);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
