// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../itf/ItfJosephUsdt.sol";

contract MockCase1JosephUsdt is ItfJosephUsdt {
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
