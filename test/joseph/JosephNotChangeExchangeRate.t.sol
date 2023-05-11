// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/milton/MockCase1MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase1MiltonUsdt.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase1JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase1JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";

contract JosephNotExchangeRate is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidity18Decimals() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(180 * TestConstants.D18, block.timestamp);
        //open position to have something in Liquidity Pool
		vm.prank(_userTwo);
		mockCase1MiltonDai.itfOpenSwapPayFixed(block.timestamp, 180 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC);
        uint256 exchangeRateBeforeProvideLiquidity = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // when
		vm.prank(_userThree);
		mockCase0JosephDai.itfProvideLiquidity(1500 * TestConstants.D18, block.timestamp);
		uint256 actualIpTokenBalanceForUserThree = _ipTokenDai.balanceOf(_userThree);
        uint256 actualExchangeRate = mockCase0JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
		assertEq(actualIpTokenBalanceForUserThree, 1187964338781575037555);
		assertEq(1262664165103189493, exchangeRateBeforeProvideLiquidity);
		assertEq(1262664165103189493, actualExchangeRate);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems18Decimals() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase1JosephDai mockCase1JosephDai = getMockCase1JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase1JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase1JosephDai), address(stanleyDai));
        prepareJoseph(mockCase1JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase1JosephDai));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
		vm.prank(_liquidityProvider);
		mockCase1JosephDai.itfProvideLiquidity(180 * TestConstants.D18, block.timestamp);
        //open position to have something in Liquidity Pool
		vm.prank(_userTwo);
		mockCase1MiltonDai.itfOpenSwapPayFixed(block.timestamp, 180 * TestConstants.D18, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC);
        uint256 exchangeRateBeforeProvideLiquidity = mockCase1JosephDai.itfCalculateExchangeRate(block.timestamp);
        // when
		vm.startPrank(_userThree);
		mockCase1JosephDai.itfProvideLiquidity(1500 * TestConstants.D18, block.timestamp);
		mockCase1JosephDai.itfRedeem(874999999999999999854, block.timestamp);
		vm.stopPrank();
		uint256 actualIpTokenBalanceForUserThree = _ipTokenDai.balanceOf(_userThree);
        uint256 actualExchangeRate = mockCase1JosephDai.itfCalculateExchangeRate(block.timestamp);
        // then
		assertEq(actualIpTokenBalanceForUserThree, 312964338781575037701);
		assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
		assertEq(actualExchangeRate, 1262664165103189493);
    }


    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1MiltonUsdt mockCase1MiltonUsdt = getMockCase1MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase1JosephUsdt mockCase1JosephUsdt = getMockCase1JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase1MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase1JosephUsdt), address(mockCase1MiltonUsdt));
        prepareMilton(mockCase1MiltonUsdt, address(mockCase1JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase1JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase1JosephUsdt));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
		vm.prank(_liquidityProvider);
		mockCase1JosephUsdt.itfProvideLiquidity(180 * TestConstants.N1__0_6DEC, block.timestamp);
        //open position to have something in Liquidity Pool
		vm.prank(_userTwo);
		mockCase1MiltonUsdt.itfOpenSwapPayFixed(block.timestamp, 180 * TestConstants.N1__0_6DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC);
        uint256 exchangeRateBeforeProvideLiquidity = mockCase1JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        // when
		vm.startPrank(_userThree);
		mockCase1JosephUsdt.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
		mockCase1JosephUsdt.itfRedeem(874999999999999999854, block.timestamp);
		vm.stopPrank();
		uint256 actualIpTokenBalanceForUserThree = _ipTokenUsdt.balanceOf(_userThree);
        uint256 actualExchangeRate = mockCase1JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        // then
		assertEq(actualIpTokenBalanceForUserThree, 312964338781575037701);
		assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
		assertEq(actualExchangeRate, 1262664166047052506);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase2() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1MiltonUsdt mockCase1MiltonUsdt = getMockCase1MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase1JosephUsdt mockCase1JosephUsdt = getMockCase1JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase1MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase1JosephUsdt), address(mockCase1MiltonUsdt));
        prepareMilton(mockCase1MiltonUsdt, address(mockCase1JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase1JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase1JosephUsdt));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
		vm.prank(_liquidityProvider);
		mockCase1JosephUsdt.itfProvideLiquidity(180 * TestConstants.N1__0_6DEC, block.timestamp);
        //open position to have something in Liquidity Pool
		vm.prank(_userTwo);
		mockCase1MiltonUsdt.itfOpenSwapPayFixed(block.timestamp, 180 * TestConstants.N1__0_6DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC);
        uint256 exchangeRateBeforeProvideLiquidity = mockCase1JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding up
        //and then user takes a little bit more stable,
        //so balance in Milton is little bit lower and finally exchange rate is little bit lower.
        // when
		vm.startPrank(_userThree);
		mockCase1JosephUsdt.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
		mockCase1JosephUsdt.itfRedeem(871111000099999999854, block.timestamp);
		vm.stopPrank();
		uint256 actualIpTokenBalanceForUserThree = _ipTokenUsdt.balanceOf(_userThree);
        uint256 actualExchangeRate = mockCase1JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        // then
		assertEq(actualIpTokenBalanceForUserThree, 316853338681575037701);
		assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
		assertEq(actualExchangeRate, 1262664164405742069);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase3() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1MiltonUsdt mockCase1MiltonUsdt = getMockCase1MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase1JosephUsdt mockCase1JosephUsdt = getMockCase1JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase1MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase1JosephUsdt), address(mockCase1MiltonUsdt));
        prepareMilton(mockCase1MiltonUsdt, address(mockCase1JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase1JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase1JosephUsdt));
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp);
		vm.prank(_liquidityProvider);
		mockCase1JosephUsdt.itfProvideLiquidity(180 * TestConstants.N1__0_6DEC, block.timestamp);
        //open position to have something in Liquidity Pool
		vm.prank(_userTwo);
		mockCase1MiltonUsdt.itfOpenSwapPayFixed(block.timestamp, 180 * TestConstants.N1__0_6DEC, 9 * TestConstants.D17, TestConstants.LEVERAGE_18DEC);
        uint256 exchangeRateBeforeProvideLiquidity = mockCase1JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding down
        //and then user takes a little bit less stable,
        //so balance in Milton is little bit higher and finally exchange rate is little bit higher .
        // when
		vm.startPrank(_userThree);
		mockCase1JosephUsdt.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
		mockCase1JosephUsdt.itfRedeem(871110090000000999854, block.timestamp);
		vm.stopPrank();
		uint256 actualIpTokenBalanceForUserThree = _ipTokenUsdt.balanceOf(_userThree);
        uint256 actualExchangeRate = mockCase1JosephUsdt.itfCalculateExchangeRate(block.timestamp);
        // then
		assertEq(actualIpTokenBalanceForUserThree, 316854248781574037701, "incorrect ipToken balance for user three");
		assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493, "incorrect exchange rate before provide liquidity");
		assertEq(actualExchangeRate, 1262664164102524851, "incorrect exchange rate");

    }

}