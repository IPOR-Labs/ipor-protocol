// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@ipor-protocol/contracts/interfaces/IIvToken.sol";
import "@ipor-protocol/contracts/libraries/errors/AssetManagementErrors.sol";
import "@ipor-protocol/contracts/security/IporOwnable.sol";

contract IvToken is IporOwnable, IIvToken, ERC20 {
    using SafeERC20 for IERC20;

    uint8 private immutable _decimals;

    address private immutable _asset;

    address private _assetManagement;

    modifier onlyAssetManagement() {
        require(_msgSender() == _assetManagement, AssetManagementErrors.CALLER_NOT_ASSET_MANAGEMENT);
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

    function setAssetManagement(address newAssetManagement) external override onlyOwner {
        require(newAssetManagement != address(0), IporErrors.WRONG_ADDRESS);
        _assetManagement = newAssetManagement;
        emit AssetManagementChanged(newAssetManagement);
    }

    function mint(address account, uint256 amount) external override onlyAssetManagement {
        require(amount > 0, AssetManagementErrors.IV_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(account, amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external override onlyAssetManagement {
        require(amount > 0, AssetManagementErrors.IV_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(account, amount);
        emit Burn(account, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
