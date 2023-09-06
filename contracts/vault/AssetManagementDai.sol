// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./AssetManagement.sol";

contract AssetManagementDai is AssetManagement {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant getVersion = 2_000;

    address public immutable strategyAave;
    address public immutable strategyCompound;
    address public immutable strategyDsr;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        address ammTreasuryInput,
        uint256 supportedStrategiesVolumeInput,
        uint256 highestApyStrategyArrayIndexInput,
        address strategyAaveInput,
        address strategyCompoundInput,
        address strategyDsrInput
    ) AssetManagement(assetInput, ammTreasuryInput, supportedStrategiesVolumeInput, highestApyStrategyArrayIndexInput) {
        strategyAave = strategyAaveInput.checkAddress();
        strategyCompound = strategyCompoundInput.checkAddress();
        strategyDsr = strategyDsrInput.checkAddress();

        _disableInitializers();
    }

    function _getDecimals() internal pure override returns (uint256) {
        return 18;
    }

    function _getStrategiesData() internal view override returns (StrategyData[] memory sortedStrategies) {
        sortedStrategies = new StrategyData[](supportedStrategiesVolume);
        sortedStrategies[0].strategy = strategyAave;
        sortedStrategies[0].balance = IStrategy(strategyAave).balanceOf();
        sortedStrategies[1].strategy = strategyCompound;
        sortedStrategies[1].balance = IStrategy(strategyCompound).balanceOf();
        sortedStrategies[2].strategy = strategyDsr;
        sortedStrategies[2].balance = IStrategy(strategyDsr).balanceOf();
    }
}
