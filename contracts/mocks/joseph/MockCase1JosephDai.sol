// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../itf/ItfJosephDai.sol";

contract MockCase1JosephDai is ItfJosephDai {
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
