// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfJosephDai.sol";

contract MockCase1Joseph18D is ItfJosephDai {
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
