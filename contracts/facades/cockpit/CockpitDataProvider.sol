// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/types/CockpitTypes.sol";
import "../../libraries/Constants.sol";
import "../../interfaces/IIporOracle.sol";
import "../../interfaces/IMilton.sol";
import "../../interfaces/IMiltonStorage.sol";
import "../../interfaces/ICockpitDataProvider.sol";
import "../../security/IporOwnableUpgradeable.sol";

contract CockpitDataProvider is IporOwnableUpgradeable, UUPSUpgradeable, ICockpitDataProvider {
    address internal _iporOracle;
    mapping(address => CockpitTypes.AssetConfig) internal _assetConfig;
    address[] internal _assets;

    function initialize(
        address iporOracle,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs,
        address[] memory ipTokens,
        address[] memory ivTokens
    ) public initializer {
        __Ownable_init();
        require(iporOracle != address(0), IporErrors.WRONG_ADDRESS);
        require(
            assets.length == miltons.length && assets.length == miltonStorages.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        _iporOracle = iporOracle;
        _assets = assets;

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i != assetsLength; i++) {
            require(assets[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(miltons[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(miltonStorages[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(josephs[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ipTokens[i] != address(0), IporErrors.WRONG_ADDRESS);
            require(ivTokens[i] != address(0), IporErrors.WRONG_ADDRESS);

            _assetConfig[assets[i]] = CockpitTypes.AssetConfig(
                miltons[i],
                miltonStorages[i],
                josephs[i],
                ipTokens[i],
                ivTokens[i]
            );
        }
    }

    function getVersion() external pure override returns (uint256) {
        return 1;
    }

    function getIndexes() external view override returns (CockpitTypes.IporFront[] memory) {
        CockpitTypes.IporFront[] memory indexes = new CockpitTypes.IporFront[](_assets.length);

        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i != assetsLength; i++) {
            indexes[i] = _createIporFront(_assets[i]);
        }
        return indexes;
    }

    function getMyIpTokenBalance(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(_assetConfig[asset].ipToken);
        return token.balanceOf(_msgSender());
    }

    function getMyIvTokenBalance(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(_assetConfig[asset].ivToken);
        return token.balanceOf(_msgSender());
    }

    function getMyTotalSupply(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(asset);
        return token.balanceOf(_msgSender());
    }

    function getMyAllowanceInMilton(address asset) external view override returns (uint256) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        IERC20 token = IERC20(asset);
        return token.allowance(_msgSender(), config.milton);
    }

    function getMyAllowanceInJoseph(address asset) external view override returns (uint256) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        IERC20 token = IERC20(asset);
        return token.allowance(_msgSender(), config.joseph);
    }

    function getSwapsPayFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        return IMiltonStorage(config.miltonStorage).getSwapsPayFixed(account, offset, chunkSize);
    }

    function getSwapsReceiveFixed(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        return
            IMiltonStorage(config.miltonStorage).getSwapsReceiveFixed(account, offset, chunkSize);
    }

    function getMySwapsPayFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        return
            IMiltonStorage(config.miltonStorage).getSwapsPayFixed(_msgSender(), offset, chunkSize);
    }

    function getMySwapsReceiveFixed(
        address asset,
        uint256 offset,
        uint256 chunkSize
    ) external view override returns (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        return
            IMiltonStorage(config.miltonStorage).getSwapsReceiveFixed(
                _msgSender(),
                offset,
                chunkSize
            );
    }

    function calculateSpread(address asset)
        external
        view
        override
        returns (int256 spreadPayFixed, int256 spreadReceiveFixed)
    {
        CockpitTypes.AssetConfig memory config = _assetConfig[asset];
        IMilton milton = IMilton(config.milton);

        try milton.calculateSpread() returns (int256 _spreadPayFixed, int256 _spreadReceiveFixed) {
            spreadPayFixed = _spreadPayFixed;
            spreadReceiveFixed = _spreadReceiveFixed;
        } catch {
            spreadPayFixed = 999999999999999999999;
            spreadReceiveFixed = 999999999999999999999;
        }
    }

    function _createIporFront(address asset)
        internal
        view
        returns (CockpitTypes.IporFront memory iporFront)
    {
        (
            uint256 value,
            uint256 ibtPrice,
            uint256 exponentialMovingAverage,
            uint256 exponentialWeightedMovingVariance,
            uint256 date
        ) = IIporOracle(_iporOracle).getIndex(asset);

        iporFront = CockpitTypes.IporFront(
            IERC20MetadataUpgradeable(asset).symbol(),
            value,
            ibtPrice,
            exponentialMovingAverage,
            exponentialWeightedMovingVariance,
            date
        );
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
