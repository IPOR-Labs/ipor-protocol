// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/math/IporMath.sol";
import "../interfaces/IIpToken.sol";
import "./IStETH.sol";


library AmmLibEth {

    function getExchangeRate(address stEth, address ethAmmTreasury, address ethIpToken) internal view returns (uint256) {
        uint256 balance = IStETH(stEth).balanceOf(ethAmmTreasury);
        uint256 ipTokenTotalSupply = IIpToken(ethIpToken).totalSupply();
        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }

}