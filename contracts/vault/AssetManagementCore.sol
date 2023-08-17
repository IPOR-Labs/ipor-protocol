// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAsset {
    function getAsset() external view returns (address);
}

abstract contract AssetManagementCore {
    struct StrategyData {
        address strategy;
        uint256 balance;
        uint256 apr;
    }

    function _getStrategiesData() internal view virtual returns (StrategyData[] memory sortedStrategies);

    function _calculateTotalBalance(
        StrategyData[] memory sortedStrategies
    ) internal view returns (uint256 returnedTotalBalance) {
        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            returnedTotalBalance += sortedStrategies[i].balance;
        }
        returnedTotalBalance += IERC20Upgradeable(asset).balanceOf(address(this));
    }

    function _getMaxApyStrategy(
        StrategyData[] memory strategies
    ) internal view returns (StrategyData[] memory) {
        uint256 length = strategies.length;
        for(uint256 i; i < length; ++i) {
            strategies[i].apr = IStrategy(strategies[i].strategy).getApr();
        }
        return _sortApr(strategies);
    }

    function _sortApr(StrategyData[] memory data) internal pure returns (StrategyData[] memory) {
        _quickSortApr(data, int256(0), int256(data.length - 1));
        return data;
    }

    function _quickSortApr(StrategyData[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        StrategyData memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].apr < pivot.apr) i++;
            while (pivot.apr < arr[uint256(j)].apr) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSortApr(arr, left, j);
        if (i < right) _quickSortApr(arr, i, right);
    }
}
