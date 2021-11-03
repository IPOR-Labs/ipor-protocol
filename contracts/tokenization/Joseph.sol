// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IIporToken.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IJoseph.sol";
import {Errors} from '../Errors.sol';
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from '../libraries/AmmMath.sol';
import "../libraries/Constants.sol";
import "../interfaces/IIporConfiguration.sol";

contract Joseph is Ownable, IJoseph {

    using SafeERC20 for IERC20;

    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    function provideLiquidity(address asset, uint256 liquidityAmount) external override {
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        _provideLiquidity(asset, liquidityAmount, iporConfiguration.getMultiplicator());
    }

    function redeem(address asset, uint256 iporTokenVolume) external override {
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        _redeem(asset, iporTokenVolume, iporConfiguration.getMultiplicator());
    }

    function calculateExchangeRate(address asset) external override view returns (uint256){
        IIporToken iporToken = IIporToken(_addressesManager.getIporToken(asset));
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());
        uint256 iporTokenTotalSupply = iporToken.totalSupply();
        IIporConfiguration iporConfiguration = IIporConfiguration(_addressesManager.getIporConfiguration(asset));
        if (iporTokenTotalSupply > 0) {
            return AmmMath.division(miltonStorage.getBalance(asset).liquidityPool * iporConfiguration.getMultiplicator(), iporTokenTotalSupply);
        } else {
            return iporConfiguration.getMultiplicator();
        }
    }

    function _provideLiquidity(address asset, uint256 liquidityAmount, uint256 multiplicator) internal {

        uint256 exchangeRate = IJoseph(_addressesManager.getJoseph()).calculateExchangeRate(asset);

        require(exchangeRate > 0, Errors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        IMiltonStorage(_addressesManager.getMiltonStorage()).addLiquidity(asset, liquidityAmount);

        //TODO: user Address from OZ and use call
        IERC20(asset).safeTransferFrom(msg.sender, _addressesManager.getMilton(), liquidityAmount);

        if (exchangeRate > 0) {
            IIporToken(_addressesManager.getIporToken(asset)).mint(msg.sender, AmmMath.division(liquidityAmount * multiplicator, exchangeRate));
        }
    }

    function _redeem(address asset, uint256 iporTokenVolume, uint256 multiplicator) internal {
        require(IIporToken(_addressesManager.getIporToken(asset)).balanceOf(msg.sender) >= iporTokenVolume, Errors.MILTON_CANNOT_REDEEM_IPOR_TOKEN_TOO_LOW);

        uint256 exchangeRate = IJoseph(_addressesManager.getJoseph()).calculateExchangeRate(asset);

        require(exchangeRate > 0, Errors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        require(IMiltonStorage(_addressesManager.getMiltonStorage()).getBalance(asset).liquidityPool > iporTokenVolume, Errors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW);

        uint256 underlyingAmount = AmmMath.division(iporTokenVolume * exchangeRate, multiplicator);

        IIporToken(_addressesManager.getIporToken(asset)).burn(msg.sender, msg.sender, iporTokenVolume);

        IMiltonStorage(_addressesManager.getMiltonStorage()).subtractLiquidity(asset, underlyingAmount);

        IERC20(asset).safeTransferFrom(_addressesManager.getMilton(), msg.sender, underlyingAmount);
    }

}
