// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import {IporErrors} from "../IporErrors.sol";
import "../interfaces/IMiltonStorage.sol";
import {IporMath} from "../libraries/IporMath.sol";
import "../libraries/Constants.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMilton.sol";

contract Joseph is Ownable, IJoseph {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

	uint8 private immutable _decimals;
	address internal _asset;


    IIporConfiguration internal _iporConfiguration;
    IIporAssetConfiguration internal _iporAssetConfiguration;
	
    constructor(address asset, address initialIporConfiguration) {
        require(address(asset) != address(0), IporErrors.WRONG_ADDRESS);
        require(
            address(initialIporConfiguration) != address(0),
            IporErrors.INCORRECT_IPOR_CONFIGURATION_ADDRESS
        );
        _iporConfiguration = IIporConfiguration(initialIporConfiguration);
        require(
            _iporConfiguration.assetSupported(asset) == 1,
            IporErrors.MILTON_ASSET_ADDRESS_NOT_SUPPORTED
        );

		address iporAssetConfigurationAddr = _iporConfiguration.getIporAssetConfiguration(asset);

		require(address(iporAssetConfigurationAddr) != address(0), IporErrors.WRONG_ADDRESS);

        _iporAssetConfiguration = IIporAssetConfiguration(
            iporAssetConfigurationAddr
        );

		_asset = asset;
		_decimals = _iporAssetConfiguration.getDecimals();
		
    }

	function decimals() external view returns (uint8) {
		return _decimals;
	}
	function asset() external view returns (address) {
		return _asset;
	}
	function getIporConfiguration() external view returns(address) {
		return address(_iporConfiguration);
	}
	function getIporAssetConfiguration() external view returns(address) {
		return address(_iporAssetConfiguration);
	}

    function provideLiquidity(uint256 liquidityAmount)
        external
        override
    {
        _provideLiquidity(
            liquidityAmount,
            _decimals,
            block.timestamp
        );
    }

    function redeem(uint256 ipTokenVolume) external override {
        _redeem(ipTokenVolume, block.timestamp);
    }

    //@param liquidityAmount in decimals like asset
    function _provideLiquidity(
        uint256 liquidityAmount,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal {
        uint256 exchangeRate = IMilton(_iporAssetConfiguration.getMilton())
            .calculateExchangeRate(timestamp);

        require(exchangeRate != 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadLiquidityAmount = IporMath.convertToWad(
            liquidityAmount,
            assetDecimals
        );

        IMiltonStorage(_iporAssetConfiguration.getMiltonStorage()).addLiquidity(
            wadLiquidityAmount
        );

        //TODO: user Address from OZ and use call
        //TODO: use call instead transfer if possible!!

        //TODO: add from address to black list
        IERC20(_asset).safeTransferFrom(
            msg.sender,
            _iporAssetConfiguration.getMilton(),
            liquidityAmount
        );

        if (exchangeRate != 0) {
            IIpToken(
                _iporAssetConfiguration.getIpToken()
            ).mint(
                    msg.sender,
                    IporMath.division(
                        wadLiquidityAmount * Constants.D18,
                        exchangeRate
                    )
                );
        }
    }

    function _redeem(
        uint256 ipTokenVolume,
        uint256 timestamp
    ) internal {

        require(
            ipTokenVolume <=
                IIpToken(_iporAssetConfiguration.getIpToken()).balanceOf(
                    msg.sender
                ),
            IporErrors.MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );

        uint256 exchangeRate = IMilton(_iporAssetConfiguration.getMilton())
            .calculateExchangeRate(timestamp);

        require(exchangeRate != 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        require(
            IMiltonStorage(_iporAssetConfiguration.getMiltonStorage())
                .getBalance()
                .liquidityPool > ipTokenVolume,
            IporErrors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW
        );
        uint256 wadUnderlyingAmount = IporMath.division(
            ipTokenVolume * exchangeRate,
            Constants.D18
        );
        uint256 underlyingAmount = IporMath.convertWadToAssetDecimals(
            wadUnderlyingAmount,
            _decimals
        );

        IIpToken(_iporAssetConfiguration.getIpToken()).burn(
            msg.sender,
            msg.sender,
            ipTokenVolume
        );

        IMiltonStorage(_iporAssetConfiguration.getMiltonStorage()).subtractLiquidity(
                wadUnderlyingAmount
            );

        IERC20(_asset).safeTransferFrom(
            _iporAssetConfiguration.getMilton(),
            msg.sender,
            underlyingAmount
        );
    }
}
