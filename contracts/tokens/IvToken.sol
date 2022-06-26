// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../libraries/errors/StanleyErrors.sol";
import "../interfaces/IIvToken.sol";
import "../security/IporOwnable.sol";

contract IvToken is IporOwnable, IIvToken, ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint8 private immutable _decimals;

    address private immutable _asset;

    address private _stanley;

    modifier onlyStanley() {
        require(_msgSender() == _stanley, StanleyErrors.CALLER_NOT_STANLEY);
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

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function setStanley(address newStanley) external override onlyOwner {
        require(newStanley != address(0), IporErrors.WRONG_ADDRESS);
        address oldStanley = _stanley;
        _stanley = newStanley;
        emit StanleyChanged(_msgSender(), oldStanley, newStanley);
    }

    function mint(address account, uint256 amount) external override onlyStanley {
        require(amount != 0, StanleyErrors.IV_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyStanley {
        require(amount != 0, StanleyErrors.IV_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(account, amount);
        emit Burn(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

contract IvTokenUsdt is IvToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IvToken(name, symbol, asset) {}
}

contract IvTokenUsdc is IvToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IvToken(name, symbol, asset) {}
}

contract IvTokenDai is IvToken {
    constructor(
        string memory name,
        string memory symbol,
        address asset
    ) IvToken(name, symbol, asset) {}
}
