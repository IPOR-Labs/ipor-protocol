// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../../contracts/libraries/math/IporMath.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephUsdc.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";

contract MiltonAutoUpdateIndex is Test, TestCommons, DataUtils {
    IporProtocol private _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
    }

    function testOpenSwapPayFixedUsdtAndAutoUpdateIndex() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        milton.setAutoUpdateIporIndexThreshold(100);

        uint256 liquidityAmount = 100000 * 10**6;
        uint256 totalAmount = 10000 * 10**6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 500 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        asset.approve(address(milton), totalAmount);
		//257638
		//271410
		//257638
		//261861
        joseph.provideLiquidity(liquidityAmount);

        //when
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        //then
    }

    // function testOpenSwapReceiveFixedUsdtAndAutoUpdateIndex() public {
    //     //given
    //     _iporProtocol = setupIporProtocolForUsdt();
    //     //when
    //     //then
    // }

    // function testOpenSwapPayFixedDaiAndAutoUpdateIndex() public {
    //     //given
    //     _iporProtocol = setupIporProtocolForDai();

    //     //when
    //     //then
    // }

    // function testOpenSwapReceiveFixedDaiAndAutoUpdateIndex() public {
    //     //given
    //     _iporProtocol = setupIporProtocolForDai();

    //     //when
    //     //then
    // }
}
