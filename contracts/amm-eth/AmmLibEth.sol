// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/math/IporMath.sol";
import "../interfaces/IIpToken.sol";
import "./IStETH.sol";


library AmmLibEth {

    /// @notice Retrieves the exchange rate between stEth and ipTokenEth.
    /// @param stEth Address of the stEth token.
    /// @param ammTreasuryEth Address of the AMM Treasury for stEth.
    /// @param ipTokenEth Address of the ipTokenEth token.
    /// @dev The exchange rate is calculated based on the balance of stEth in the AMM Treasury and the total supply of ipTokenEth.
    /// If the total supply of ipTokenEth is zero, the function returns 1e18.
    function getExchangeRate(address stEth, address ammTreasuryEth, address ipTokenEth) internal view returns (uint256) {
        uint256 ipTokenTotalSupply = IIpToken(ipTokenEth).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(IStETH(stEth).balanceOf(ammTreasuryEth) * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }

}