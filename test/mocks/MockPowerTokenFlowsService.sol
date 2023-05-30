// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/IPowerTokenFlowsService.sol";

contract MockPowerTokenFlowsService is IPowerTokenFlowsService {
    function claimRewardsFromLiquidityMining(address[] calldata lpTokens) external {}

    function updateIndicatorsInLiquidityMining(address account, address[] calldata lpTokens) external {}

    function delegateLpTokensToLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts)
        external
    {}

    function undelegateLpTokensFromLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts)
        external
    {}
}
