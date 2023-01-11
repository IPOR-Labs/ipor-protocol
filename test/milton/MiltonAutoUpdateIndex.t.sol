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

        //when
        //then
    }

    function testOpenSwapReceiveFixedUsdtAndAutoUpdateIndex() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
        //when
        //then
    }

    function testOpenSwapPayFixedDaiAndAutoUpdateIndex() public {
        //given
        _iporProtocol = setupIporProtocolForDai();

        //when
        //then
    }

    function testOpenSwapReceiveFixedDaiAndAutoUpdateIndex() public {
        //given
        _iporProtocol = setupIporProtocolForDai();

        //when
        //then
    }
}
