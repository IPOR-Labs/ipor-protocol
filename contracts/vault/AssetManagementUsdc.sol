// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/errors/AssetManagementErrors.sol";

import "./AssetManagementCore.sol";

contract AssetManagementUsdc is AssetManagementCore {
    using IporContractValidator for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant getVersion = 2_000;

    address public immutable strategyAave;
    address public immutable strategyCompound;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address assetInput,
        address ammTreasuryInput,
        uint256 supportedStrategiesVolumeInput,
        uint256 highestApyStrategyArrayIndexInput,
        address strategyAaveInput,
        address strategyCompoundInput
    )
        AssetManagementCore(
            assetInput,
            ammTreasuryInput,
            supportedStrategiesVolumeInput,
            highestApyStrategyArrayIndexInput
        )
    {
        strategyAave = strategyAaveInput.checkAddress();
        strategyCompound = strategyCompoundInput.checkAddress();

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IStrategy(strategyAaveInput).asset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(
            _getDecimals() == IERC20MetadataUpgradeable(IStrategy(strategyCompoundInput).asset()).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        require(IStrategy(strategyAaveInput).asset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);
        require(IStrategy(strategyCompoundInput).asset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        _disableInitializers();
    }

    function _getDecimals() internal pure override returns (uint256) {
        return 6;
    }

    function _getStrategiesData() internal view override returns (StrategyData[] memory sortedStrategies) {
        sortedStrategies = new StrategyData[](supportedStrategiesVolume);
        sortedStrategies[0].strategy = strategyAave;
        sortedStrategies[0].balance = IStrategy(strategyAave).balanceOf();
        sortedStrategies[1].strategy = strategyCompound;
        sortedStrategies[1].balance = IStrategy(strategyCompound).balanceOf();
    }
}
