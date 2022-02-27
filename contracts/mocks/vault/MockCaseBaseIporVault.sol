// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IIporVault.sol";
import "../../libraries/IporMath.sol";
import {IporErrors} from "../../IporErrors.sol";

contract MockCaseBaseIporVault is IIporVault {
    using SafeERC20 for IERC20;
    IERC20 private _asset;

    mapping(address => uint256) private _balance;

    uint256 private constant _FIXED_IV_TOKEN_PRICE = 1e18;

    constructor(address asset) {
        _asset = IERC20(asset);
    }

    function totalBalance(address who)
        external
        view
        override
        returns (uint256)
    {
        //@dev for simplicity we assome that reading total balance not include interest
        return _balance[who];
    }

    //@dev for test purposes, simulation that IporVault earn some money for recipient
    function testDeposit(address recipient, uint256 assetValue)
        external
        returns (uint256 balance)
    {
        balance = _balance[recipient] + assetValue;

        _balance[recipient] = balance;

        _asset.safeTransferFrom(msg.sender, address(this), assetValue);
    }

    function deposit(uint256 assetValue)
        external
        override
        returns (uint256 balance)
    {
        //@dev assume that every deposit returns some fixed interest, which is interest from last rebalance
        //Notice! asset balance ERC20 for IporVault should be increased with interest, but for simplicity is not increased!
        uint256 interest = _getCurrentInterest();

        balance = _balance[msg.sender] + interest + assetValue;

        _balance[msg.sender] = balance;

        _asset.safeTransferFrom(msg.sender, address(this), assetValue);
    }

    function withdraw(uint256 assetValue)
        external
        override
        returns (uint256 balance)
    {
        //@dev assume that every withdraw returns some fixed interest, which is interest from last rebalance
        //Notice! asset balance ERC20 for IporVault should be increased with interest, but for simplicity is not increased!
        uint256 interest = _getCurrentInterest();

        balance = _balance[msg.sender] + interest - assetValue;

        _balance[msg.sender] = balance;

        //@dev assume that IPOR Vault will withdraw 100% assetValue
        _asset.safeTransfer(msg.sender, assetValue);
    }

    function _getCurrentInterest() internal pure virtual returns (uint256) {
        //@dev for test purposes always the same fixed interest for any msg.sender
        return 0;
    }
}
