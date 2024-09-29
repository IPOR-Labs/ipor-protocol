// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIpToken.sol";
import "../libraries/errors/IporErrors.sol";
import "../libraries/errors/AmmErrors.sol";
import "../libraries/errors/AmmPoolsErrors.sol";
import "../security/IporOwnable.sol";

contract IpToken is IporOwnable, IIpToken, ERC20 {
    using SafeERC20 for IERC20;

    address private immutable _asset;

    uint8 private immutable _decimals;

    address private _tokenManager;

    modifier onlyTokenManager() {
        require(msg.sender == _tokenManager, AmmErrors.CALLER_NOT_TOKEN_MANAGER);
        _;
    }

    constructor(string memory name, string memory symbol, address asset) ERC20(name, symbol) {
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

    function getTokenManager() external view override returns (address) {
        return _tokenManager;
    }

    function setTokenManager(address newTokenManager) external override onlyOwner {
        require(newTokenManager != address(0), IporErrors.WRONG_ADDRESS);
        _tokenManager = newTokenManager;
        emit TokenManagerChanged(newTokenManager);
    }

    function mint(address account, uint256 amount) external override onlyTokenManager {
        require(amount > 0, AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyTokenManager {
        require(amount > 0, AmmPoolsErrors.IP_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(account, amount);
        emit Burn(account, amount);
    }
}
