// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

import "../interfaces/IIvToken.sol";
import "../../security/IporOwnable.sol";
import "../../IporErrors.sol";

contract IvToken is IporOwnable, IIvToken, ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint8 private immutable _decimals;

    address private immutable _asset;

    address private _stanley;

    modifier onlyStanley() {
        require(msg.sender == _stanley, IporErrors.CALLER_NOT_STANLEY);
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

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setStanley(address newStanley) external onlyOwner {
        _stanley = newStanley;
        emit StanleyChanged(msg.sender, newStanley);
    }

    function mint(address account, uint256 amount)
        external
        override
        onlyStanley
    {
        require(amount != 0, IporErrors.STANLEY_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyStanley
    {
        require(amount != 0, IporErrors.STANLEY_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(account, amount);
        emit Burn(account, amount);
    }
}
