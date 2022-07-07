// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/MiltonErrors.sol";
import "../libraries/errors/JosephErrors.sol";
import "../interfaces/IIpToken.sol";
import "../security/IporOwnable.sol";

contract IpToken is IporOwnable, IIpToken, ERC20 {
    using SafeERC20 for IERC20;

    address private immutable _asset;

    uint8 private immutable _decimals;

    address private _joseph;

    modifier onlyJoseph() {
        require(_msgSender() == _joseph, MiltonErrors.CALLER_NOT_JOSEPH);
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) ERC20(name, symbol) {
        require(address(0) != asset, IporErrors.WRONG_ADDRESS);
        _asset = asset;
        _decimals = 18;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function setJoseph(address newJoseph) external override onlyOwner {
        require(newJoseph != address(0), IporErrors.WRONG_ADDRESS);
        address oldJoseph = _joseph;
        _joseph = newJoseph;
        emit JosephChanged(_msgSender(), oldJoseph, newJoseph);
    }

    function mint(address account, uint256 amount) external override onlyJoseph {
        require(amount != 0, JosephErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyJoseph {
        require(amount != 0, JosephErrors.IP_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(account, amount);
        emit Burn(account, amount);
    }
}

contract IpTokenUsdt is IpToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IpToken(name, symbol, asset) {}
}

contract IpTokenUsdc is IpToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IpToken(name, symbol, asset) {}
}

contract IpTokenDai is IpToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IpToken(name, symbol, asset) {}
}
