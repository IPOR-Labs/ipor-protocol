// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "contracts/interfaces/IPowerTokenLens.sol";
import "../utils/builder/BuilderUtils.sol";

contract MockPowerTokenLens is IPowerTokenLens {
    BuilderUtils.PowerTokenLensData private _data;

    constructor(BuilderUtils.PowerTokenLensData memory builderData) {
        _data = builderData;
    }

    function totalSupplyOfPwToken() external view returns (uint256) {
        return _data.totalSupply;
    }

    function balanceOfPwToken(address account) external view returns (uint256) {
        return _data.balanceOf;
    }

    function balanceOfPwTokenDelegatedToLiquidityMining(address account) external view returns (uint256) {
        return _data.delegatedPowerTokensToLiquidityMiningBalanceOf;
    }

    function getPwTokenUnstakeFee() external view returns (uint256) {
        return _data.getUnstakeWithoutCooldownFee;
    }

    function getPwTokensInCooldown(address account)
        external
        view
        returns (PwTokenCooldown memory)
    {
        return _data.activeCooldown;
    }

    function getPwTokenCooldownTime() external view returns (uint256) {
        return _data.coolDownInSeconds;
    }

    function getPwTokenExchangeRate() external view returns (uint256) {
        return _data.exchangeRate;
    }

    function getPwTokenTotalSupplyBase() external view returns (uint256) {
        return _data.totalSupplyBase;
    }
}
