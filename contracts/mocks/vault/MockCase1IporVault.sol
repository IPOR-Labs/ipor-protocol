// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IIporVault.sol";
import "../../libraries/IporMath.sol";

contract MockCase1IporVault is IIporVault {
	
    using SafeERC20 for IERC20;
    IERC20 private _asset;

    mapping(address => uint256) internal _balance;

    uint256 private constant _FIXED_INTEREST = 2e16;
    uint256 private constant _FIXED_IV_TOKEN_PRICE = 1e18;

    constructor(address asset) {
        _asset = IERC20(asset);
    }

    function totalBalance(address who) external view override returns (uint256) {
        return _balance[who];
    }

    function deposit(uint256 assetValue)
        external
        override
        returns (uint256 currentBalance, uint256 currentInterest)
    {
        //@dev assume that every deposit returns some fixed interest
        _balance[msg.sender] = _balance[msg.sender] + _FIXED_INTEREST + assetValue;
        currentBalance = _balance[msg.sender];
        currentInterest = _FIXED_INTEREST;

        _asset.safeTransferFrom(msg.sender, address(this), assetValue);
    }

    function withdraw(uint256 ivTokenValue)
        external
        override
        returns (uint256 withdrawAssetValue, uint256 currentInterest)
    {
        //@dev assume that every withdraw returns some fixed interest
        withdrawAssetValue = IporMath.division(
            ivTokenValue * _FIXED_IV_TOKEN_PRICE,
            Constants.D18
        );
        _balance[msg.sender] =
            _balance[msg.sender] +
            _FIXED_INTEREST -
            withdrawAssetValue;

        currentInterest = _FIXED_INTEREST;

        _asset.safeTransfer(msg.sender, withdrawAssetValue);
    }

    function currentInterest(address who) external override returns (uint256) {
        //@dev for test purposes always the same fixed interest for any msg.sender
        return _FIXED_INTEREST;
    }

	function authorizeMilton(address milton)
        external
        override
    {
        IERC20(_asset).safeIncreaseAllowance(
            milton,
            Constants.MAX_VALUE
        );
    }
}
