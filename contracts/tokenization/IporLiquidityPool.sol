// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIporToken.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IIporLiquidityPool.sol";
import {Errors} from '../Errors.sol';
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from '../libraries/AmmMath.sol';
import "../libraries/Constants.sol";

contract IporLiquidityPool is Ownable, IIporLiquidityPool {
    event LogDebug(string name, uint256 value);
    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    function calculateExchangeRate(address asset) external override returns (uint256){
        IIporToken iporToken = IIporToken(_addressesManager.getIporToken(asset));
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());
        uint256 iporTokenTotalSupply = iporToken.totalSupply();
        emit LogDebug("iporTokenTotalSupply", iporTokenTotalSupply);
        emit LogDebug("lpBalance", miltonStorage.getBalance(asset).liquidityPool);
        if (iporTokenTotalSupply > 0) {
            uint256 result = AmmMath.division(miltonStorage.getBalance(asset).liquidityPool * Constants.MD, iporTokenTotalSupply);
            emit LogDebug("result", result);
            return result;
        } else {
            return Constants.MD;
        }
    }
//
//    function redeem(address asset, uint256 iporTokenVolume) external override {
//        //TODO: do final implementation, will be described in separate task
//
//        require(IporToken(_addressesManager.getIporToken(asset)).balanceOf(msg.sender) >= iporTokenVolume, Errors.MILTON_CANNOT_WITHDRAW_IPOR_TOKEN_TOO_LOW);
//
//        uint256 exchangeRate = IIporLiquidityPool(_addressesManager.getIporLiquidityPool()).calculateExchangeRate(asset);
//        uint256 underlyingAmount = iporTokenVolume * exchangeRate;
//
//        require(IMiltonStorage(_addressesManager.getMiltonStorage()).getBalance(asset).liquidityPool > underlyingAmount, Errors.MILTON_CANNOT_WITHDRAW_LIQUIDITY_POOL_IS_TOO_LOW);
//
//        IporToken(_addressesManager.getIporToken(asset)).burn(msg.sender, msg.sender, iporTokenVolume);
//
//        IMiltonStorage(_addressesManager.getMiltonStorage()).subtractLiquidity(asset, underlyingAmount);
//
//        IERC20(asset).transferFrom(_addressesManager.getMilton(),msg.sender, underlyingAmount);
//    }

}
