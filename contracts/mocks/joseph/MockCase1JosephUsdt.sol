// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../itf/ItfJosephUsdt.sol";

contract MockCase1JosephUsdt is ItfJosephUsdt {
    function _getRedeemFeeRate() internal pure virtual override returns (uint256) {
        return 0;
    }
}
