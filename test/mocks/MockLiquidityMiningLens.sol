// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/ILiquidityMiningLens.sol";
import "../utils/builder/BuilderUtils.sol";

contract MockLiquidityMiningLens is ILiquidityMiningLens {
    BuilderUtils.LiquidityMiningLensData private _data;

    constructor(BuilderUtils.LiquidityMiningLensData memory builderData) {
        _data = builderData;
    }

    function getLiquidityMiningContractId() external view returns (bytes32) {
        return _data.contractId;
    }

    function liquidityMiningBalanceOf(address account, address lpToken) external view returns (uint256) {
        return _data.balanceOf;
    }

    function balanceOfDelegatedPowerToken(address account, address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.DelegatedPwTokenBalance[] memory balances)
    {}

    function calculateLiquidityMiningAccruedRewards(address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccruedRewardsResult[] memory result)
    {}

    function calculateLiquidityMiningAccountRewards(address account, address[] calldata lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccountRewardResult[] memory)
    {}

    function getLiquidityMiningGlobalIndicators(address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.GlobalIndicatorsResult[] memory)
    {}

    function getLiquidityMiningAccountIndicators(address account, address[] memory lpTokens)
        external
        view
        returns (LiquidityMiningTypes.AccountIndicatorsResult[] memory)
    {}
}
