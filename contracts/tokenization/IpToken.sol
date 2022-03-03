// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../security/IporOwnable.sol";
import "../interfaces/IIpToken.sol";
import {IporErrors} from "../IporErrors.sol";

contract IpToken is IporOwnable, IIpToken, ERC20 {
    using SafeERC20 for IERC20;

    address private immutable _asset;
    uint8 private immutable _decimals;

    address private _joseph;

    modifier onlyJoseph() {
        require(msg.sender == _joseph, IporErrors.MILTON_CALLER_NOT_JOSEPH);
        _;
    }

    constructor(
        address asset,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        require(address(0) != asset, IporErrors.WRONG_ADDRESS);
        _asset = asset;
        _decimals = 18;
        _joseph = msg.sender;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setJoseph(address newJoseph) external onlyOwner {
        _joseph = newJoseph;
    }

    function mint(address account, uint256 value) external override onlyJoseph {
        require(value != 0, IporErrors.IP_TOKEN_MINT_VALUE_TOO_LOW);
        _mint(account, value);
        emit Transfer(address(0), account, value);
        emit Mint(account, value);
    }

    function burn(
        address account,
        address assetReceiver,
        uint256 value
    ) external override onlyJoseph {
        require(value != 0, IporErrors.IP_TOKEN_BURN_VALUE_TOO_LOW);
        _burn(account, value);

        emit Transfer(account, address(0), value);
        emit Burn(account, assetReceiver, value);
    }
}
