// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";

//TODO: change name to CockpitDataProvider
contract MiltonDevToolDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IMiltonDevToolDataProvider
{
    address internal _warren;
    mapping(address => AssetConfig) internal _assetConfig;

    function initialize(
        address warren,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs,
        address[] memory ipTokens,
        address[] memory ivTokens
    ) public initializer {
        require(
            assets.length == miltons.length && assets.length == miltonStorages.length,
            IporErrors.INPUT_ARRAYS_LENGTH_MISMATCH
        );

        __Ownable_init();
        _warren = warren;

        uint256 i = 0;
        for (i; i != assets.length; i++) {
            _assetConfig[assets[i]] = AssetConfig(
                miltons[i],
                miltonStorages[i],
                josephs[i],
                ipTokens[i],
                ivTokens[i]
            );
        }
    }

    function getMyIpTokenBalance(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(_assetConfig[asset].ipToken);
        return token.balanceOf(msg.sender);
    }

    function getMyIvTokenBalance(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(_assetConfig[asset].ivToken);
        return token.balanceOf(msg.sender);
    }

    function getMyTotalSupply(address asset) external view override returns (uint256) {
        IERC20 token = IERC20(asset);
        return token.balanceOf(msg.sender);
    }

    function getMyAllowanceInMilton(address asset) external view override returns (uint256) {
        AssetConfig memory config = _assetConfig[asset];
        IERC20 token = IERC20(asset);
        return token.allowance(msg.sender, config.milton);
    }

    function getMyAllowanceInJoseph(address asset) external view override returns (uint256) {
        AssetConfig memory config = _assetConfig[asset];
        IERC20 token = IERC20(asset);
        return token.allowance(msg.sender, config.joseph);
    }

    function getSwapsPayFixed(address asset, address account)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        AssetConfig memory config = _assetConfig[asset];
        return IMiltonStorage(config.miltonStorage).getSwapsPayFixed(account);
    }

    function getSwapsReceiveFixed(address asset, address account)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        AssetConfig memory config = _assetConfig[asset];
        return IMiltonStorage(config.miltonStorage).getSwapsReceiveFixed(account);
    }

    function getMySwapsPayFixed(address asset)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory items)
    {
        AssetConfig memory config = _assetConfig[asset];
        return IMiltonStorage(config.miltonStorage).getSwapsPayFixed(msg.sender);
    }

    function getMySwapsReceiveFixed(address asset)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory items)
    {
        AssetConfig memory config = _assetConfig[asset];
        return IMiltonStorage(config.miltonStorage).getSwapsReceiveFixed(msg.sender);
    }

    function calculateSpread(address asset)
        external
        view
        override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        AssetConfig memory config = _assetConfig[asset];
        IMilton milton = IMilton(config.milton);

        try milton.calculateSpread() returns (
            uint256 _spreadPayFixedValue,
            uint256 _spreadRecFixedValue
        ) {
            spreadPayFixedValue = _spreadPayFixedValue;
            spreadRecFixedValue = _spreadRecFixedValue;
        } catch {
            spreadPayFixedValue = 999999999999999999999;
            spreadRecFixedValue = 999999999999999999999;
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
