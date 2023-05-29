// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/IPowerTokenLens.sol";

contract MockPowerTokenLens is IPowerTokenLens {

    PowerTokenData private _data;

    constructor (PowerTokenData memory builderData) {
        _data = builderData;
    }

    function powerTokenName() external view returns (string memory) {
        return _data.name;
    }

    function getPowerTokenContractId() external view returns (bytes32) {
        return _data.contractId;
    }

    function powerTokenSymbol() external view returns (string memory) {
        return _data.symbol;
    }

    function powerTokenDecimals() external view returns (uint8) {
        return _data.decimals;
    }

    function powerTokenTotalSupply() external view returns (uint256) {
        return _data.totalSupply;
    }

    function powerTokenBalanceOf(address account) external view returns (uint256) {
        return _data.balanceOf;
    }

    function delegatedPowerTokensToLiquidityMiningBalanceOf(address account) external view returns (uint256) {
        return _data.delegatedPowerTokensToLiquidityMiningBalanceOf;
    }

    function getUnstakeWithoutCooldownFee() external view returns (uint256) {
        return _data.getUnstakeWithoutCooldownFee;
    }

    function getPowerTokenActiveCooldown(address account)
        external
        view
        returns (PowerTokenTypes.PwTokenCooldown memory)
    {
        return _data.activeCooldown;
    }

    function powerTokenCoolDownTime() external view returns (uint256) {
        return _data.coolDownInSeconds;
    }

    function calculatePowerTokenExchangeRate() external view returns (uint256) {
        return _data.exchangeRate;
    }

    function totalPowerTokenSupplyBase() external view returns (uint256) {
        return _data.totalSupplyBase;
    }
}
