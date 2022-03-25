// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../../itf/ItfJosephUsdc.sol";

contract MockCase1JosephUsdc is ItfJosephUsdc {
    function _getRedeemFeePercentage() internal pure virtual override returns (uint256) {
        return 0;
    }
}
