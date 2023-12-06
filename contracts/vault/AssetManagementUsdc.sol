// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AssetManagement.sol";

contract AssetManagementUsdc is AssetManagement {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant getVersion = 2_000;

    address public immutable strategyAave;
    address public immutable strategyCompound;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        address ammTreasuryInput,
        address strategyAaveInput,
        address strategyCompoundInput
    ) AssetManagement(assetInput, ammTreasuryInput) {
        strategyAave = strategyAaveInput.checkAddress();
        strategyCompound = strategyCompoundInput.checkAddress();

        _disableInitializers();
    }

    function _getDecimals() internal pure override returns (uint256) {
        return 6;
    }

    function _getNumberOfSupportedStrategies() internal view virtual override returns (uint256) {
        return 2;
    }

    function _getStrategiesData() internal view override returns (StrategyData[] memory strategies) {
        strategies = new StrategyData[](_getNumberOfSupportedStrategies());
        strategies[0].strategy = strategyAave;
        strategies[0].balance = IStrategy(strategyAave).balanceOf();
        strategies[1].strategy = strategyCompound;
        strategies[1].balance = IStrategy(strategyCompound).balanceOf();
    }
}
