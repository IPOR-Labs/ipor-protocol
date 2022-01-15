// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IMiltonStorage.sol";
import "../interfaces/IMiltonDevToolDataProvider.sol";
import "../interfaces/IIporAssetConfiguration.sol";

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
        IERC20 token = IERC20(asset);
        return token.allowance(msg.sender, _iporConfiguration.getMilton());
    }

    function getMyAllowanceInJoseph(address asset)
        external
        view
        override
        returns (uint256)
    {
        IERC20 token = IERC20(asset);
        return token.allowance(msg.sender, _iporConfiguration.getJoseph());
    }

    function getSwapsPayFixed()
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory)
    {
        return
            IMiltonStorage(_iporConfiguration.getMiltonStorage()).getSwapsPayFixed();
    }

	function getSwapsReceiveFixed()
	external
	view
	override
	returns (DataTypes.IporDerivative[] memory)
{
	return
		IMiltonStorage(_iporConfiguration.getMiltonStorage()).getSwapsReceiveFixed();
}
    function getMySwapsPayFixed()
        external
        view
        override
        returns (DataTypes.IporDerivative[] memory items)
    {
        return
            IMiltonStorage(_iporConfiguration.getMiltonStorage())
                .getUserSwapsPayFixed(msg.sender);
    }

	function getMySwapsReceiveFixed()
	external
	view
	override
	returns (DataTypes.IporDerivative[] memory items)
{
	return
		IMiltonStorage(_iporConfiguration.getMiltonStorage())
			.getUserSwapsReceiveFixed(msg.sender);
}

    //@notice FOR TEST ONLY
    //    function getOpenPosition(uint256 derivativeId) external view returns (DataTypes.IporDerivative memory) {
    //        return milton.getDerivatives().items[derivativeId].item;
    //    }
}
