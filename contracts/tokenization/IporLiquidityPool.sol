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
    
    IIporAddressesManager internal _addressesManager;

    function initialize(IIporAddressesManager addressesManager) public onlyOwner {
        _addressesManager = addressesManager;
    }

    function calculateExchangeRate(address asset) external override returns (uint256){
        IIporToken iporToken = IIporToken(_addressesManager.getIporToken(asset));
        IMiltonStorage miltonStorage = IMiltonStorage(_addressesManager.getMiltonStorage());
        uint256 iporTokenTotalSupply = iporToken.totalSupply();

        if (iporTokenTotalSupply > 0) {
            uint256 result = AmmMath.division(miltonStorage.getBalance(asset).liquidityPool * Constants.MD, iporTokenTotalSupply);
            return result;
        } else {
            return Constants.MD;
        }
    }

}
