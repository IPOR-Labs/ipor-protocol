// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../itf/ItfJosephUsdc.sol";

contract MockCase1JosephUsdc is ItfJosephUsdc {
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
