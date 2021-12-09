// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporConfiguration.sol";
import "../interfaces/IJoseph.sol";
import { Errors } from "../Errors.sol";
import "../interfaces/IMiltonStorage.sol";
import { AmmMath } from "../libraries/AmmMath.sol";
import "../libraries/Constants.sol";
import "./Joseph.sol";

contract TestJoseph is Joseph {
    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for minting ipToken
    function test_provideLiquidity(
        address asset,
        uint256 liquidityAmount,
        uint256 timestamp
    ) external {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(
                iporConfiguration.getIporAssetConfiguration(asset)
            );
        _provideLiquidity(
            asset,
            liquidityAmount,
            iporAssetConfiguration.getDecimals(),
            timestamp
        );
    }

    //@notice timestamp is required because SOAP changes over time, SOAP is a part of exchange rate calculation used for burning ipToken
    function test_redeem(
        address asset,
        uint256 ipTokenVolume,
        uint256 timestamp
    ) external {
        _redeem(asset, ipTokenVolume, timestamp);
    }
}
