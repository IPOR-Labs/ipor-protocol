// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IIpToken.sol";
import "../interfaces/IIporAddressesManager.sol";
import "../interfaces/IJoseph.sol";
import {Errors} from '../Errors.sol';
import "../interfaces/IMiltonStorage.sol";
import {AmmMath} from '../libraries/AmmMath.sol';
import "../libraries/Constants.sol";
import "./Joseph.sol";

contract TestJoseph is Joseph {

    function test_provideLiquidity(address asset, uint256 liquidityAmount) external {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset));
        _provideLiquidity(asset, liquidityAmount, iporAssetConfiguration.getMultiplicator());
    }

    function test_redeem(address asset, uint256 ipTokenVolume) external {
        IIporAssetConfiguration iporAssetConfiguration = IIporAssetConfiguration(_addressesManager.getIporAssetConfiguration(asset));
        _redeem(asset, ipTokenVolume, iporAssetConfiguration.getMultiplicator());
    }
}