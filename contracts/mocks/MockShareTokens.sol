//solhint-disable no-empty-blocks
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../mocks/stanley/compound/MockCToken.sol";
import "../mocks/stanley/compound/MockComptroller.sol";

contract MockCDai is MockCToken {
    constructor(address asset, address interestRateModel)
        MockCToken(asset, interestRateModel, 18, "cDAI", "cDAI")
    {}
}

contract MockCUSDT is MockCToken {
    constructor(address asset, address interestRateModel)
        MockCToken(asset, interestRateModel, 6, "cUSDT", "cUSDT")
    {}
}

contract MockCUSDC is MockCToken {
    constructor(address asset, address interestRateModel)
        MockCToken(asset, interestRateModel, 6, "cUSDC", "cUSDC")
    {}
}
