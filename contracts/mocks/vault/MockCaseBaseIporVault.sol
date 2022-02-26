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

    uint256 internal _miltonBalance;

    uint256 private constant _FIXED_IV_TOKEN_PRICE = 1e18;

    constructor(address asset) {
        _asset = IERC20(asset);
    }

    function totalBalance() external view override returns (uint256) {
        return _miltonBalance;
    }

    function deposit(uint256 assetValue)
        external
        override
        returns (uint256 currentInterest)
    {
        //@dev assume that every deposit returns some fixed interest
        _miltonBalance = _miltonBalance + _getCurrentInterest() + assetValue;
        currentInterest = _getCurrentInterest();

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
        _miltonBalance =
            _miltonBalance +
            _getCurrentInterest() -
            withdrawAssetValue;

        currentInterest = _getCurrentInterest();

        _asset.safeTransfer(msg.sender, withdrawAssetValue);
    }

    function getCurrentInterest()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _getCurrentInterest();
    }

    function _getCurrentInterest() internal pure virtual returns (uint256) {
        //@dev for test purposes always the same fixed interest for any msg.sender
        return 0;
    }
}
