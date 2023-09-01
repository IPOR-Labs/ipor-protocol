// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "../libraries/errors/IporErrors.sol";
import "../interfaces/IStrategy.sol";

interface IAsset {
    function getAsset() external view returns (address);
}

abstract contract AssetManagementCore {
    struct StrategyData {
        address strategy;
        uint256 balance;
        uint256 apy;
    }

    //TODO: change to immutable because others strategies will be added
    uint256 internal constant _SUPPORTED_STRATEGIES_VOLUME = 3;
    uint256 internal constant _HIGHEST_APY_STRATEGY_ARRAY_INDEX = 2;

    address public immutable asset;
    address public immutable ammTreasury;

    constructor(address assetInput, address ammTreasuryInput) {
        require(assetInput != address(0), IporErrors.WRONG_ADDRESS);
        require(ammTreasuryInput != address(0), IporErrors.WRONG_ADDRESS);

        require(_getDecimals() == IERC20MetadataUpgradeable(assetInput).decimals(), IporErrors.WRONG_DECIMALS);

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IAsset(ammTreasuryInput).getAsset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        asset = assetInput;
        ammTreasury = ammTreasuryInput;
    }

    function _getDecimals() internal pure virtual returns (uint256);

    function _getStrategiesData() internal view virtual returns (StrategyData[] memory sortedStrategies);

    function _calculateTotalBalance(
        StrategyData[] memory sortedStrategies
    ) internal view returns (uint256 totalBalance) {
        for (uint256 i; i < _SUPPORTED_STRATEGIES_VOLUME; ++i) {
            totalBalance += sortedStrategies[i].balance;
        }
        totalBalance += IERC20Upgradeable(asset).balanceOf(address(this));
    }

    function _getMaxApyStrategy(StrategyData[] memory strategies) internal view returns (StrategyData[] memory) {
        uint256 length = strategies.length;
        for (uint256 i; i < length; ++i) {
            strategies[i].apy = IStrategy(strategies[i].strategy).getApy();
        }
        return _sortApy(strategies);
    }

    function _sortApy(StrategyData[] memory data) internal pure returns (StrategyData[] memory) {
        _quickSortApy(data, int256(0), int256(data.length - 1));
        return data;
    }

    function _quickSortApy(StrategyData[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        StrategyData memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].apy < pivot.apy) i++;
            while (pivot.apy < arr[uint256(j)].apy) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSortApy(arr, left, j);
        if (i < right) _quickSortApy(arr, i, right);
    }
}
