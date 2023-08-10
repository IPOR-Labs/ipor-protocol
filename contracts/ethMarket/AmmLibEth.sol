// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/math/IporMath.sol";
import "../interfaces/IIpToken.sol";
import "./IStETH.sol";

import "forge-std/console2.sol";


library AmmLibEth {

    function getExchangeRate(address stEth, address ammTreasuryEth, address ipTokenEth) internal view returns (uint256) {
        uint256 balance = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint256 ipTokenTotalSupply = IIpToken(ipTokenEth).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(balance * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }

}