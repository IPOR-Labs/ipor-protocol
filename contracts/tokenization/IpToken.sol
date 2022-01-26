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

    address private immutable _underlyingAsset;
    uint8 private immutable _decimals;

	IIporAssetConfiguration internal _iporAssetConfiguration;

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

    function mint(address account, uint256 amount) external override onlyJoseph {
        require(amount != 0, IporErrors.MILTON_IPOT_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(account, amount);
        emit Transfer(address(0), account, amount);
        emit Mint(account, amount);
    }

    function burn(
        address account,
        address receiverOfUnderlying,
        uint256 amount
    ) external override onlyJoseph {
        require(amount != 0, IporErrors.MILTON_IPOT_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(account, amount);

        emit Transfer(account, address(0), amount);
        emit Burn(account, receiverOfUnderlying, amount);
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
