// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import {Errors} from '../Errors.sol';
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from '../libraries/AmmMath.sol';
import "../libraries/Constants.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMilton.sol";

contract Joseph is Ownable, IJoseph {

    using SafeERC20 for IERC20;

    IIporConfiguration internal _iporConfiguration;

    function initialize(IIporConfiguration addressesManager) public onlyOwner {
        _iporConfiguration = addressesManager;
    }

    function provideLiquidity(address asset, uint256 liquidityAmount) external override {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        _provideLiquidity(asset, liquidityAmount, iporAssetConfiguration.getMultiplicator());
    }

    function redeem(address asset, uint256 ipTokenVolume) external override {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        _redeem(asset, ipTokenVolume, iporAssetConfiguration.getMultiplicator());
    }
    event LogDebug(string name, uint256 value);
    function calculateExchangeRate(address asset) external override returns (uint256){
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        IIpToken ipToken = IIpToken(iporAssetConfiguration.getIpToken());
        IMiltonStorage miltonStorage = IMiltonStorage(_iporConfiguration.getMiltonStorage());
        IMilton milton = IMilton(_iporConfiguration.getMilton());
//        (int256 soapPf, int256 soapRf, int256 soap) = milton.calculateSoap(asset);
        uint256 ipTokenTotalSupply = ipToken.totalSupply();
        emit LogDebug("ipTokenTotalSupply", ipTokenTotalSupply);
        emit LogDebug("MiltonLiquidityPoolBalance", miltonStorage.getBalance(asset).liquidityPool);
        if (ipTokenTotalSupply > 0) {
            return AmmMath.division((miltonStorage.getBalance(asset).liquidityPool) * iporAssetConfiguration.getMultiplicator(), ipTokenTotalSupply);
        } else {
            return iporAssetConfiguration.getMultiplicator();
        }
    }

    function _provideLiquidity(address asset, uint256 liquidityAmount, uint256 multiplicator) internal {

        uint256 exchangeRate = IJoseph(_iporConfiguration.getJoseph()).calculateExchangeRate(asset);

//        require(exchangeRate > 0, Errors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        IMiltonStorage(_iporConfiguration.getMiltonStorage()).addLiquidity(asset, liquidityAmount);

        //TODO: user Address from OZ and use call
        //TODO: zastosuj call zamiast transfer1!!
        IERC20(asset).safeTransferFrom(msg.sender, _iporConfiguration.getMilton(), liquidityAmount);

        if (exchangeRate > 0) {
            IIpToken(IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset)).getIpToken())
                .mint(msg.sender, AmmMath.division(liquidityAmount * multiplicator, exchangeRate));
        }
    }

    function _redeem(address asset, uint256 ipTokenVolume, uint256 multiplicator) internal {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));

        require(IIpToken(iporAssetConfiguration.getIpToken()).balanceOf(msg.sender) >= ipTokenVolume, Errors.MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW);

        uint256 exchangeRate = IJoseph(_iporConfiguration.getJoseph()).calculateExchangeRate(asset);

        require(exchangeRate > 0, Errors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        require(IMiltonStorage(_iporConfiguration.getMiltonStorage()).getBalance(asset).liquidityPool > ipTokenVolume, Errors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW);

        uint256 underlyingAmount = AmmMath.division(ipTokenVolume * exchangeRate, multiplicator);

        IIpToken(iporAssetConfiguration.getIpToken()).burn(msg.sender, msg.sender, ipTokenVolume);

        IMiltonStorage(_iporConfiguration.getMiltonStorage()).subtractLiquidity(asset, underlyingAmount);

        IERC20(asset).safeTransferFrom(_iporConfiguration.getMilton(), msg.sender, underlyingAmount);
    }

}
