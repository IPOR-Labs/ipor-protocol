//solhint-disable no-empty-blocks
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "../mocks/stanley/MockTestnetStrategy.sol";
import "../mocks/stanley/MockTestnetStrategyV2.sol";

contract MockTestnetStrategyCompoundUsdt is MockTestnetStrategy {}

contract MockTestnetStrategyCompoundUsdc is MockTestnetStrategy {}

contract MockTestnetStrategyCompoundDai is MockTestnetStrategy {}

contract MockTestnetStrategyAaveUsdt is MockTestnetStrategy {}

contract MockTestnetStrategyAaveUsdc is MockTestnetStrategy {}

contract MockTestnetStrategyAaveDai is MockTestnetStrategy {}

contract MockTestnetStrategyCompoundUsdtV2 is MockTestnetStrategyV2 {}

contract MockTestnetStrategyCompoundUsdcV2 is MockTestnetStrategyV2 {}

contract MockTestnetStrategyCompoundDaiV2 is MockTestnetStrategyV2 {}
