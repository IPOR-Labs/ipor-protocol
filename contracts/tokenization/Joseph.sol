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

    IIporConfiguration internal _iporConfiguration;

	constructor (address initialIporConfiguration) {
		_iporConfiguration = IIporConfiguration(initialIporConfiguration);
	}    

    function provideLiquidity(address asset, uint256 liquidityAmount)
        external
        override
    {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );
        _provideLiquidity(
            asset,
            liquidityAmount,
            iporAssetConfiguration.getDecimals(),
            block.timestamp
        );
    }

    function redeem(address asset, uint256 ipTokenVolume) external override {
        _redeem(asset, ipTokenVolume, block.timestamp);
    }

    //@param liquidityAmount in decimals like asset
    function _provideLiquidity(
        address asset,
        uint256 liquidityAmount,
        uint256 assetDecimals,
        uint256 timestamp
    ) internal {
        uint256 exchangeRate = IMilton(_iporConfiguration.getMilton())
            .calculateExchangeRate(asset, timestamp);

        require(exchangeRate > 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        uint256 wadLiquidityAmount = IporMath.convertToWad(
            liquidityAmount,
            assetDecimals
        );

        IMiltonStorage(_iporConfiguration.getMiltonStorage()).addLiquidity(
            asset,
            wadLiquidityAmount
        );

        //TODO: user Address from OZ and use call
        //TODO: use call instead transfer if possible!!

        //TODO: add from address to black list
        IERC20(asset).safeTransferFrom(
            msg.sender,
            _iporConfiguration.getMilton(),
            liquidityAmount
        );

        if (exchangeRate > 0) {
            IIpToken(
                IIporAssetConfiguration(
                    _iporConfiguration.getIporAssetConfiguration(asset)
                ).getIpToken()
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
        address asset,
        uint256 ipTokenVolume,
        uint256 timestamp
    ) internal {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                _iporConfiguration.getIporAssetConfiguration(asset)
            );

        require(
            ipTokenVolume <=
                IIpToken(iporAssetConfiguration.getIpToken()).balanceOf(
                    msg.sender
                ),
            IporErrors.MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );

        uint256 exchangeRate = IMilton(_iporConfiguration.getMilton())
            .calculateExchangeRate(asset, timestamp);

        require(exchangeRate > 0, IporErrors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        require(
            IMiltonStorage(_iporConfiguration.getMiltonStorage())
                .getBalance(asset)
                .liquidityPool > ipTokenVolume,
            IporErrors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW
        );
        uint256 wadUnderlyingAmount = IporMath.division(
            ipTokenVolume * exchangeRate,
            Constants.D18
        );
        uint256 underlyingAmount = IporMath.convertWadToAssetDecimals(
            wadUnderlyingAmount,
            iporAssetConfiguration.getDecimals()
        );

        IIpToken(iporAssetConfiguration.getIpToken()).burn(
            msg.sender,
            msg.sender,
            ipTokenVolume
        );

        IMiltonStorage(_iporConfiguration.getMiltonStorage()).subtractLiquidity(
                asset,
                wadUnderlyingAmount
            );

        IERC20(asset).safeTransferFrom(
            _iporConfiguration.getMilton(),
            msg.sender,
            underlyingAmount
        );
    }
}
