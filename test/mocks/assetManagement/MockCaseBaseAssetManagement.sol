// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../../contracts/libraries/errors/IporErrors.sol";
import "../../../contracts/libraries/math/IporMath.sol";
import "../../../contracts/interfaces/IAssetManagement.sol";

contract MockCaseBaseAssetManagement is IAssetManagement {
    using SafeERC20 for IERC20;
    IERC20 private _asset;

    uint256 private _balance;

    function initialize(address asset, address strategyAave, address strategyCompound) public {
        require(strategyAave != address(0) || strategyCompound != address(0), IporErrors.WRONG_ADDRESS);
        _asset = IERC20(asset);
    }

    function setAsset(address asset) external {
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        _asset = IERC20(asset);
    }

    function setAmmTreasury(address newAmmTreasury) external {}

    function totalBalance() external view override returns (uint256) {
        //@dev for simplicity we assume that reading total balance not include interest
        return _balance;
    }


    //@dev for test purposes, simulation that IporVault earn some money for recipient
    function forTestDeposit(address recipient, uint256 assetAmount) external returns (uint256 balance) {
        balance = _balance + assetAmount;
        _balance = balance;
        _asset.safeTransferFrom(msg.sender, address(this), assetAmount);
    }

    function deposit(uint256 wadAssetAmount) external override returns (uint256 balance, uint256 depositedAmount) {
        balance = _balance + wadAssetAmount;

        _balance = balance;

        uint256 decimals = IERC20Metadata(address(_asset)).decimals();

        uint256 assetAmount = IporMath.convertWadToAssetDecimals(wadAssetAmount, decimals);

        _asset.safeTransferFrom(msg.sender, address(this), assetAmount);

        depositedAmount = IporMath.convertToWad(assetAmount, decimals);
    }

    function withdraw(uint256 wadAssetAmount) external override returns (uint256 withdrawnAmount, uint256 balance) {
        uint256 wadFinalAssetAmount = IporMath.division(wadAssetAmount * _withdrawRate(), 1e18);
        if (wadFinalAssetAmount > _balance) {
            return (0, _balance);
        }
        balance = _balance - wadFinalAssetAmount;
        withdrawnAmount = wadFinalAssetAmount;

        _balance = balance;

        uint256 finalAssetAmount = IporMath.convertWadToAssetDecimals(
            wadFinalAssetAmount,
            IERC20Metadata(address(_asset)).decimals()
        );
        _asset.safeTransfer(msg.sender, finalAssetAmount);
    }

    //solhint-disable no-empty-blocks
    function withdrawAll() external override returns (uint256 withdrawnAmount, uint256 vaultBalance) {
        uint256 toWithdraw = _balance;
        _asset.safeTransfer(msg.sender, toWithdraw);
        withdrawnAmount = _balance;
        _balance = 0;
        vaultBalance = 0;
    }

    function _withdrawRate() internal pure virtual returns (uint256) {
        return 1e18;
    }
}
