// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/math/IporMath.sol";
import "../interfaces/IIpToken.sol";
import "./interfaces/IStETH.sol";

/// @title Library for AMM operations with ETH.
library AmmLibEth {
    /// @notice Retrieves the exchange rate between stEth and ipstETH.
    /// @param stEth Address of the stEth token.
    /// @param ipstEth Address of the IP Token of stETH.
    /// @param ammTreasuryEth Address of the AMM Treasury for stEth.
    /// @dev The exchange rate is calculated based on the balance of stEth in the AMM Treasury and the total supply of ipstEth.
    /// If the total supply of ipstEth is zero, the function returns 1e18.
    function getExchangeRate(address stEth, address ipstEth, address ammTreasuryEth) internal view returns (uint256) {
        uint256 ipTokenTotalSupply = IIpToken(ipstEth).totalSupply();

        if (ipTokenTotalSupply > 0) {
            return IporMath.division(IStETH(stEth).balanceOf(ammTreasuryEth) * 1e18, ipTokenTotalSupply);
        } else {
            return 1e18;
        }
    }
}
