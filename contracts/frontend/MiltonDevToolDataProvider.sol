// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";
import "../interfaces/IIporAssetConfiguration.sol";

//TODO: consider dev tool per asset
contract MiltonDevToolDataProvider is IMiltonDevToolDataProvider {
    IIporConfiguration private immutable _iporConfiguration;

    constructor(IIporConfiguration iporConfiguration) {
        _iporConfiguration = iporConfiguration;
    }
    function getMyIpTokenBalance(address asset)
        external
        view
        override
        returns (uint256)
    {
        IERC20 token = IERC20(
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
        IERC20 token = IERC20(asset);
        return token.balanceOf(msg.sender);
    }

    function getMyAllowanceInMilton(address asset)
        external
        view
        override
        returns (uint256)
    {
		IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        IERC20 token = IERC20(asset);
        return token.allowance(msg.sender, assetConfiguration.getMilton());
    }

    function getMyAllowanceInJoseph(address asset)
        external
        view
        override
        returns (uint256)
    {
        IERC20 token = IERC20(asset);
		IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        return token.allowance(msg.sender, assetConfiguration.getJoseph());
    }

    function getSwapsPayFixed(address asset)
        external
        view
        override
        returns (DataTypes.IporDerivativeMemory[] memory)
    {
		IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        return
            IMiltonStorage(assetConfiguration.getMiltonStorage()).getSwapsPayFixed();
    }

	function getSwapsReceiveFixed(address asset)
	external
	view
	override
	returns (DataTypes.IporDerivativeMemory[] memory)
{
	IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
	return
		IMiltonStorage(assetConfiguration.getMiltonStorage()).getSwapsReceiveFixed();
}
    function getMySwapsPayFixed(address asset)
        external
        view
        override
        returns (DataTypes.IporDerivativeMemory[] memory items)
    {
		IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
        return
            IMiltonStorage(assetConfiguration.getMiltonStorage())
                .getUserSwapsPayFixed(msg.sender);
    }

	function getMySwapsReceiveFixed(address asset)
	external
	view
	override
	returns (DataTypes.IporDerivativeMemory[] memory items)
{
	IIporAssetConfiguration assetConfiguration = IIporAssetConfiguration(_iporConfiguration.getIporAssetConfiguration(asset));
	return
		IMiltonStorage(assetConfiguration.getMiltonStorage())
			.getUserSwapsReceiveFixed(msg.sender);
}

    //@notice FOR TEST ONLY
    //    function getOpenPosition(uint256 derivativeId) external view returns (DataTypes.IporDerivative memory) {
    //        return milton.getDerivatives().items[derivativeId].item;
    //    }
}
