// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@ipor-protocol/contracts/interfaces/IPowerTokenStakeService.sol";

contract MockPowerTokenStakeService is IPowerTokenStakeService {
    function stakeLpTokensToLiquidityMining(
        address beneficiary,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external {}

    function unstakeLpTokensFromLiquidityMining(
        address transferTo,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external {}

    function stakeGovernanceTokenToPowerToken(address beneficiary, uint256 iporTokenAmount) external {}

    function unstakeGovernanceTokenFromPowerToken(address transferTo, uint256 iporTokenAmount) external {}

    function pwTokenCooldown(uint256 pwTokenAmount) external {}

    function pwTokenCancelCooldown() external {}

    function redeemPwToken(address transferTo) external {}
}
