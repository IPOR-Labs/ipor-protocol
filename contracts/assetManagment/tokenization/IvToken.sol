// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

import "../interfaces/IIvToken.sol";
import "../../security/IporOwnable.sol";
import "../errors/Errors.sol";

contract IvToken is IporOwnable, IIvToken, ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint8 private immutable _decimals;
    address private immutable _underlyingAsset;
    address private _vault;

    modifier onlyVault() {
        require(msg.sender == _vault, Errors.ONLY_VAULT);
        _;
    }

    constructor(
        string memory aTokenName,
        string memory aTokenSymbol,
        address underlyingAsset
    ) ERC20(aTokenName, aTokenSymbol) {
        require(address(0) != underlyingAsset, Errors.ZERO_ADDRESS);
        _underlyingAsset = underlyingAsset;
        _decimals = 18;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setVault(address newVault) external onlyOwner {
        _vault = newVault;
        emit Vault(msg.sender, newVault);
    }

    function mint(address user, uint256 amount)
        external
        override
        onlyVault
        returns (bool)
    {
        require(amount > 0, Errors.IPOR_VAULT_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(user, amount);
        emit Transfer(address(0), user, amount);
        emit Mint(user, amount);
    }

    function burn(address user, uint256 amount) external override onlyVault {
        require(amount > 0, Errors.IPOR_VAULT_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(user, amount);

        emit Transfer(user, address(0), amount);
        emit Burn(user, amount);
    }

    function getUnderlyingAssetAddress()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }
}
