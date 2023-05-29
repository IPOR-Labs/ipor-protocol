// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/IFlowsService.sol";

contract MockFlowsService is IFlowsService {
    function claimPowerToken(address[] calldata lpTokens) external {}

    function updateIndicators(address account, address[] calldata lpTokens) external {}

    function delegateLpTokensToLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts)
        external
    {}

    function undelegateLpTokensFromLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts)
        external
    {}
}
