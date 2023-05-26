// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.16;

import "../interfaces/IPowerTokenLens.sol";
import "../interfaces/IPowerTokenV2.sol";
import "../interfaces/IPowerTokenInternalV2.sol";
import "../libraries/errors/PowerTokenErrors.sol";

contract PowerTokenLens is IPowerTokenLens {
    address public immutable POWER_TOKEN;

    constructor(address powerToken) {
        require(powerToken != address(0), string.concat(Errors.WRONG_ADDRESS, " powerToken"));
        POWER_TOKEN = powerToken;
    }

    function powerTokenName() external view override returns (string memory) {
        return IPowerTokenV2(POWER_TOKEN).name();
    }

    function getPowerTokenContractId() external view returns (bytes32) {
        return IPowerTokenV2(POWER_TOKEN).getContractId();
    }

    function powerTokenSymbol() external view override returns (string memory) {
        return IPowerTokenV2(POWER_TOKEN).symbol();
    }

    function powerTokenDecimals() external view returns (uint8) {
        return IPowerTokenV2(POWER_TOKEN).decimals();
    }

    function powerTokenTotalSupply() external view override returns (uint256) {
        return IPowerTokenV2(POWER_TOKEN).totalSupply();
    }

    function powerTokenBalanceOf(address account) external view override returns (uint256) {
        return IPowerTokenV2(POWER_TOKEN).balanceOf(account);
    }

    function delegatedToLiquidityMiningBalanceOf(address account) external view override returns (uint256) {
        return IPowerTokenV2(POWER_TOKEN).delegatedToLiquidityMiningBalanceOf(account);
    }

    function getUnstakeWithoutCooldownFee() external view returns (uint256) {
        return IPowerTokenV2(POWER_TOKEN).getUnstakeWithoutCooldownFee();
    }

    function getActiveCooldown(address account) external view returns (PowerTokenTypes.PwTokenCooldown memory) {
        return IPowerTokenV2(POWER_TOKEN).getActiveCooldown(account);
    }

    function COOL_DOWN_IN_SECONDS() external view returns (uint256) {
        return IPowerTokenInternalV2(POWER_TOKEN).COOL_DOWN_IN_SECONDS();
    }

    function calculateExchangeRate() external view returns (uint256) {
        return IPowerTokenInternalV2(POWER_TOKEN).calculateExchangeRate();
    }
}
