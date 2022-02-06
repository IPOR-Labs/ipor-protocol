// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";
import "../interfaces/IIporAssetConfiguration.sol";

contract MiltonDevToolDataProvider is
    OwnableUpgradeable,
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

    function getSwapsPayFixed(address asset, address account)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return
            IMiltonStorage(assetConfiguration.getMiltonStorage())
                .getSwapsPayFixed(account);
    }

    function getSwapsReceiveFixed(address asset, address account)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return
            IMiltonStorage(assetConfiguration.getMiltonStorage())
                .getSwapsReceiveFixed(account);
    }

    function getMySwapsPayFixed(address asset)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory items)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return
            IMiltonStorage(assetConfiguration.getMiltonStorage())
                .getSwapsPayFixed(msg.sender);
    }

    function getMySwapsReceiveFixed(address asset)
        external
        view
        override
        returns (DataTypes.IporSwapMemory[] memory items)
    {
        IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(
            _iporConfiguration.getIporAssetConfiguration(asset)
        );
        return
            IMiltonStorage(assetConfiguration.getMiltonStorage())
                .getSwapsReceiveFixed(msg.sender);
    }
}
