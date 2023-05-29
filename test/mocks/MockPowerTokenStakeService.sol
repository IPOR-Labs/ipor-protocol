// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/IStakeService.sol";

contract MockPowerTokenStakeService is IPowerTokenStakeService {
    function stakeLpTokensToLiquidityMining(
        address onBehalfOf,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external {}

    function unstakeLpTokensFromLiquidityMining(
        address transferTo,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external {}

    function stakeProtocolToken(address onBehalfOf, uint256 iporTokenAmount) external {}

    function unstakeProtocolToken(address transferTo, uint256 iporTokenAmount) external {}

    function cooldownPowerToken(uint256 pwTokenAmount) external {}

    function cancelPowerTokenCooldown() external {}

    function redeemPowerToken(address transferTo) external {}
}
