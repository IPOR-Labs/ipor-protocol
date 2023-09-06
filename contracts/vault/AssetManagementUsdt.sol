// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../libraries/errors/AssetManagementErrors.sol";

import "./AssetManagementCore.sol";

contract AssetManagementUsdt is AssetManagementCore {
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
        require(strategyAaveInput != address(0), IporErrors.WRONG_ADDRESS);
        require(strategyCompoundInput != address(0), IporErrors.WRONG_ADDRESS);

        //        require(
        //            _getDecimals() == IERC20MetadataUpgradeable(IAssetCheck(strategyAaveInput).getAsset()).decimals(),
        //            IporErrors.WRONG_DECIMALS
        //        );
        //
        //        require(
        //            _getDecimals() == IERC20MetadataUpgradeable(IAssetCheck(strategyCompoundInput).getAsset()).decimals(),
        //            IporErrors.WRONG_DECIMALS
        //        );
        //
        //        require(
        //            _getDecimals() == IERC20MetadataUpgradeable(IAssetCheck(strategyDsrInput).getAsset()).decimals(),
        //            IporErrors.WRONG_DECIMALS
        //        );
        //
        //        IStrategy strategyAaveObj = IStrategy(strategyAaveInput);
        //        require(strategyAaveObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);
        //
        //        IStrategy strategyCompoundObj = IStrategy(strategyCompoundInput);
        //        require(strategyCompoundObj.getAsset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        //        IStrategy.sol strategyDsrObj = IStrategy.sol(strategyDsrInput);
        //        require(strategyDsrObj.asset() == address(assetInput), AssetManagementErrors.ASSET_MISMATCH);

        strategyAave = strategyAaveInput;
        strategyCompound = strategyCompoundInput;

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
