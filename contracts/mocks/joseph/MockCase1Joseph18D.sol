// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../itf/ItfJoseph18D.sol";

contract MockCase1Joseph18D is ItfJoseph18D {
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
