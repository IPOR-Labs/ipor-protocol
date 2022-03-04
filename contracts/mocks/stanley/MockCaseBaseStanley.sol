// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IStanley.sol";
import "../../libraries/IporMath.sol";
import {IporErrors} from "../../IporErrors.sol";

contract MockCaseBaseStanley is IStanley {
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
        //@dev for simplicity we assume that reading total balance not include interest
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
        balance = _balance[msg.sender] + assetValue;

        _balance[msg.sender] = balance;

        _asset.safeTransferFrom(msg.sender, address(this), assetValue);
    }

    function withdraw(uint256 assetValue)
        external
        override
        returns (uint256 withdrawnValue, uint256 balance)
    {
        uint256 finalAssetValue = IporMath.division(
            assetValue * _withdrawPercentage(),
            Constants.D18
        );

        balance = _balance[msg.sender] - finalAssetValue;
        withdrawnValue = finalAssetValue;

        _balance[msg.sender] = balance;

        _asset.safeTransfer(msg.sender, finalAssetValue);
    }

    function withdrawAll() external override {}

    function _getCurrentInterest() internal pure virtual returns (uint256) {
        //@dev for test purposes always the same fixed interest for any msg.sender
        return 0;
    }

    function _withdrawPercentage() internal pure virtual returns (uint256) {
        return 1e18;
    }
}
