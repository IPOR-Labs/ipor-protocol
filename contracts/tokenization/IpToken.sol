// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import {IporErrors} from "../IporErrors.sol";

contract IpToken is Ownable, IIpToken, ERC20 {
    using SafeERC20 for IERC20;

    IIporAssetConfiguration internal _iporAssetConfiguration;

    address private _underlyingAsset;
    uint8 private _decimals;

    modifier onlyJoseph() {
        require(
            //TODO: avoid external call
            msg.sender == _iporAssetConfiguration.getJoseph(),
            IporErrors.MILTON_CALLER_NOT_JOSEPH
        );
        _;
    }

    constructor(
        address underlyingAsset,
        string memory aTokenName,
        string memory aTokenSymbol
    ) ERC20(aTokenName, aTokenSymbol) {
        require(address(0) != underlyingAsset, IporErrors.WRONG_ADDRESS);
        _underlyingAsset = underlyingAsset;
        _decimals = 18;
    }

    //TODO: initialization only once
    function initialize(IIporAssetConfiguration iporAssetConfiguration)
        external
        onlyOwner
    {
        _iporAssetConfiguration = iporAssetConfiguration;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address user, uint256 amount) external override onlyJoseph {
        require(amount > 0, IporErrors.MILTON_IPOT_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(user, amount);
        emit Transfer(address(0), user, amount);
        emit Mint(user, amount);
    }

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount
    ) external override onlyJoseph {
        require(amount > 0, IporErrors.MILTON_IPOT_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(user, amount);

        emit Transfer(user, address(0), amount);
        emit Burn(user, receiverOfUnderlying, amount);
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
