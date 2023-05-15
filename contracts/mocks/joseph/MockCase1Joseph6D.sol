// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfJoseph.sol";

contract MockCase1Joseph6D is ItfJoseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
