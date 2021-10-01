// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIporToken.sol";
import "../interfaces/IIporAddressesManager.sol";
import {Errors} from '../Errors.sol';

contract IporToken is Ownable, IIporToken, ERC20 {

//    using SafeERC20 for IERC20;

    IIporAddressesManager internal _addressesManager;

    address internal _underlyingAsset;
    uint8 _decimals;

    constructor(
        address underlyingAsset,
        uint8 aTokenDecimals,
        string memory aTokenName,
        string memory aTokenSymbol) ERC20(aTokenName, aTokenSymbol) {
        _underlyingAsset = underlyingAsset;
        _decimals = aTokenDecimals;
    }

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(
        address user,
        uint256 amount
    ) external override onlyMilton returns (bool) {
        uint256 previousBalance = super.balanceOf(user);
        require(amount > 0, Errors.MILTON_IPOT_TOKEN_MINT_AMOUNT_TOO_LOW);
        _mint(user, amount);
        emit Transfer(address(0), user, amount);
        emit Mint(user, amount);

        return previousBalance == 0;
    }

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount
    ) external override onlyMilton {

        require(amount > 0, Errors.MILTON_IPOT_TOKEN_BURN_AMOUNT_TOO_LOW);
        _burn(user, amount);

        emit Transfer(user, address(0), amount);
        emit Burn(user, receiverOfUnderlying, amount);
    }

    function getUnderlyingAssetAddress() public override view returns (address) {
        return _underlyingAsset;
    }

    modifier onlyMilton() {
        require(msg.sender == _addressesManager.getMilton(), Errors.MILTON_CALLER_NOT_MILTON);
        _;
    }
}
