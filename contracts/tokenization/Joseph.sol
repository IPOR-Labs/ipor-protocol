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
import { Errors } from "../Errors.sol";
import "../interfaces/IMiltonStorage.sol";
import { AmmMath } from "../libraries/AmmMath.sol";
import "../libraries/Constants.sol";
import "../interfaces/IIporAssetConfiguration.sol";
import "../interfaces/IMilton.sol";

contract Joseph is Ownable, IJoseph {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    IIporConfiguration internal iporConfiguration;

	//TODO: initialization only once
    function initialize(IIporConfiguration initialIporConfiguration) external onlyOwner {
        iporConfiguration = initialIporConfiguration;
    }

    function provideLiquidity(address asset, uint256 liquidityAmount)
        external
        override
    {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        _provideLiquidity(
            asset,
            liquidityAmount,
            iporAssetConfiguration.getMultiplicator(),
            block.timestamp
        );
    }

    function redeem(address asset, uint256 ipTokenVolume) external override {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        _redeem(
            asset,
            ipTokenVolume,
            iporAssetConfiguration.getMultiplicator(),
            block.timestamp
        );
    }

    function _provideLiquidity(
        address asset,
        uint256 liquidityAmount,
        uint256 multiplicator,
        uint256 timestamp
    ) internal {
        uint256 exchangeRate = IMilton(iporConfiguration.getMilton())
            .calculateExchangeRate(asset, timestamp);

        require(exchangeRate > 0, Errors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        IMiltonStorage(iporConfiguration.getMiltonStorage()).addLiquidity(
            asset,
            liquidityAmount
        );

        //TODO: user Address from OZ and use call
        //TODO: use call instead transfer if possible!!

        //TODO: add from address to black list
        IERC20(asset).safeTransferFrom(
            msg.sender,
            iporConfiguration.getMilton(),
            liquidityAmount
        );

        if (exchangeRate > 0) {
            IIpToken(
                IIporAssetConfiguration(
                    iporConfiguration.getIporAssetConfiguration(asset)
                ).getIpToken()
            ).mint(
                    msg.sender,
                    AmmMath.division(
                        liquidityAmount * multiplicator,
                        exchangeRate
                    )
                );	
        }
    }

    function _redeem(
        address asset,
        uint256 ipTokenVolume,
        uint256 multiplicator,
        uint256 timestamp
    ) internal {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );

        require(
            ipTokenVolume <=
                IIpToken(iporAssetConfiguration.getIpToken()).balanceOf(
                    msg.sender
                ),
            Errors.MILTON_CANNOT_REDEEM_IP_TOKEN_TOO_LOW
        );

        uint256 exchangeRate = IMilton(iporConfiguration.getMilton())
            .calculateExchangeRate(asset, timestamp);

        require(exchangeRate > 0, Errors.MILTON_LIQUIDITY_POOL_IS_EMPTY);

        require(
            IMiltonStorage(iporConfiguration.getMiltonStorage())
                .getBalance(asset)
                .liquidityPool > ipTokenVolume,
            Errors.MILTON_CANNOT_REDEEM_LIQUIDITY_POOL_IS_TOO_LOW
        );

        uint256 underlyingAmount = AmmMath.division(
            ipTokenVolume * exchangeRate,
            multiplicator
        );

        IIpToken(iporAssetConfiguration.getIpToken()).burn(
            msg.sender,
            msg.sender,
            ipTokenVolume
        );

        IMiltonStorage(iporConfiguration.getMiltonStorage()).subtractLiquidity(
                asset,
                underlyingAmount
            );

        IERC20(asset).safeTransferFrom(
            iporConfiguration.getMilton(),
            msg.sender,
            underlyingAmount
        );
    }
}
