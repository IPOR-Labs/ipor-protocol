// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../libraries/errors/IporErrors.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../interfaces/IStanley.sol";

contract MockCaseBaseStanley is IStanley {
    using SafeERC20 for IERC20;
    IERC20 private _asset;

    mapping(address => uint256) private _balance;

    uint256 private constant _FIXED_IV_TOKEN_PRICE = 1e18;

    constructor(address asset) {
        _asset = IERC20(asset);
    }

    function totalBalance(address who) external view override returns (uint256) {
        //@dev for simplicity we assume that reading total balance not include interest
        return _balance[who];
    }

    function calculateExchangeRate() external pure override returns (uint256) {
        return 0;
    }

    //@dev for test purposes, simulation that IporVault earn some money for recipient
    function testDeposit(address recipient, uint256 assetAmount)
        external
        returns (uint256 balance)
    {
        balance = _balance[recipient] + assetAmount;

        _balance[recipient] = balance;

        _asset.safeTransferFrom(msg.sender, address(this), assetAmount);
    }

    function deposit(uint256 assetAmount) external override returns (uint256 balance) {
        balance = _balance[msg.sender] + assetAmount;

        _balance[msg.sender] = balance;

        _asset.safeTransferFrom(msg.sender, address(this), assetAmount);
    }

    function withdraw(uint256 assetAmount)
        external
        override
        returns (uint256 withdrawnAmount, uint256 balance)
    {
        uint256 finalAssetAmount = IporMath.division(
            assetAmount * _withdrawPercentage(),
            Constants.D18
        );

        balance = _balance[msg.sender] - finalAssetAmount;
        withdrawnAmount = finalAssetAmount;

        _balance[msg.sender] = balance;

        _asset.safeTransfer(msg.sender, finalAssetAmount);
    }

    //solhint-disable no-empty-blocks
    function withdrawAll()
        external
        override
        returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {}

    function _getCurrentInterest() internal pure virtual returns (uint256) {
        //@dev for test purposes always the same fixed interest for any msg.sender
        return 0;
    }

    function _withdrawPercentage() internal pure virtual returns (uint256) {
        return 1e18;
    }
}
