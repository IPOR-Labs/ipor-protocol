// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMilton.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../libraries/Constants.sol";

//TODO: change name to CockpitDataProvider
contract MiltonDevToolDataProvider is
    IporOwnableUpgradeable,
    UUPSUpgradeable,
    IMiltonDevToolDataProvider
{
    IIporConfiguration private _iporConfiguration;

    function initialize(IIporConfiguration iporConfiguration)
        public
        initializer
    {
        __Ownable_init();
        _iporConfiguration = iporConfiguration;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getMyIpTokenBalance(address asset)
        external
        view
        override
        returns (uint256)
    {
        IERC20Upgradeable token = IERC20Upgradeable(
            IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            ).getIpToken()
        );
        return token.balanceOf(msg.sender);
    }

    function getMyTotalSupply(address asset)
        external
        view
        override
        returns (uint256)
    {
        IERC20Upgradeable token = IERC20Upgradeable(asset);
        return token.balanceOf(msg.sender);
    }

    function getMyAllowanceInMilton(address asset)
        external
        view
        override
        returns (uint256)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        IERC20Upgradeable token = IERC20Upgradeable(asset);
        return token.allowance(msg.sender, assetConfiguration.getMilton());
    }

    function getMyAllowanceInJoseph(address asset)
        external
        view
        override
        returns (uint256)
    {
        IERC20Upgradeable token = IERC20Upgradeable(asset);
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return token.allowance(msg.sender, assetConfiguration.getJoseph());
    }

    function getSwapsPayFixed(address asset, address account, uint256 offset, uint256 chunkSize)
        external
        view
        override
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return IMiltonStorage(assetConfiguration.getMiltonStorage())
            .getSwapsPayFixed(account, offset, chunkSize);
    }

    function getSwapsReceiveFixed(address asset, address account, uint256 offset, uint256 chunkSize)
        external
        view
        override
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return IMiltonStorage(assetConfiguration.getMiltonStorage())
            .getSwapsReceiveFixed(account, offset, chunkSize);
    }

    function getMySwapsPayFixed(address asset, uint256 offset, uint256 chunkSize)
        external
        view
        override
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return IMiltonStorage(assetConfiguration.getMiltonStorage())
            .getSwapsPayFixed(msg.sender, offset, chunkSize);
    }

    function getMySwapsReceiveFixed(address asset, uint256 offset, uint256 chunkSize)
        external
        view
        override
        returns (uint256 totalCount, DataTypes.IporSwapMemory[] memory swaps)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return IMiltonStorage(assetConfiguration.getMiltonStorage())
            .getSwapsReceiveFixed(msg.sender, offset, chunkSize);
    }

    function calculateSpread(address asset)
        external view override
        returns (uint256 spreadPayFixedValue, uint256 spreadRecFixedValue)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );

        IMilton milton = IMilton(assetConfiguration.getMilton());

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
}
