// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../../contracts/interfaces/ILiquidityMiningLens.sol";
import "../utils/builder/BuilderUtils.sol";

contract MockLiquidityMiningLens is ILiquidityMiningLens {
    BuilderUtils.LiquidityMiningLensData private _data;

    constructor(BuilderUtils.LiquidityMiningLensData memory builderData) {
        _data = builderData;
    }

    function balanceOfLpTokensStakedInLiquidityMining(address account, address lpToken) external view returns (uint256) {
        return _data.balanceOf;
    }

    function balanceOfPowerTokensDelegatedToLiquidityMining(address account, address[] memory lpTokens)
        external
        view
        returns (DelegatedPwTokenBalance[] memory balances)
    {}

    function getAccruedRewardsInLiquidityMining(address[] calldata lpTokens)
        external
        view
        returns (AccruedRewardsResult[] memory result)
    {}

    function getAccountRewardsInLiquidityMining(address account, address[] calldata lpTokens)
        external
        view
        returns (AccountRewardResult[] memory)
    {}

    function getGlobalIndicatorsFromLiquidityMining(address[] memory lpTokens)
        external
        view
        returns (GlobalIndicatorsResult[] memory)
    {}

    function getAccountIndicatorsFromLiquidityMining(address account, address[] memory lpTokens)
        external
        view
        returns (AccountIndicatorsResult[] memory)
    {}
}
