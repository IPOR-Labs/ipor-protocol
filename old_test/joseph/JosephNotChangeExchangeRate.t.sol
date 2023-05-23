// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/itf/ItfJoseph.sol";

contract JosephNotExchangeRate is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;
        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.ZERO,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidity18Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(180 * TestConstants.D18);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            180 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // when
        vm.prank(_userThree);
        _iporProtocol.joseph.provideLiquidity(1500 * TestConstants.D18);

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(actualIpTokenBalanceForUserThree, 1187964338781575037555);
        assertEq(1262664165103189493, exchangeRateBeforeProvideLiquidity);
        assertEq(1262664165103189493, actualExchangeRate);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems18Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE1;
        _cfg.josephImplementation = address(new ItfJoseph(18, true));
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(180 * TestConstants.D18);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            180 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.provideLiquidity(1500 * TestConstants.D18);
        _iporProtocol.joseph.itfRedeem(874999999999999999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(actualIpTokenBalanceForUserThree, 312964338781575037701);
        assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
        assertEq(actualExchangeRate, 1262664165103189493);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE1;
        _cfg.josephImplementation = address(new ItfJoseph(6, true));
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(180 * TestConstants.N1__0_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.provideLiquidity(1500 * TestConstants.N1__0_6DEC);
        _iporProtocol.joseph.itfRedeem(874999999999999999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(actualIpTokenBalanceForUserThree, 312964338781575037701);
        assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
        assertEq(actualExchangeRate, 1262664166047052506);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase2() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE1;
        _cfg.josephImplementation = address(new ItfJoseph(6, true));
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(180 * TestConstants.N1__0_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding up
        //and then user takes a little bit more stable,
        //so balance in AmmTreasury is little bit lower and finally exchange rate is little bit lower.

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.provideLiquidity(1500 * TestConstants.N1__0_6DEC);
        _iporProtocol.joseph.itfRedeem(871111000099999999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(actualIpTokenBalanceForUserThree, 316853338681575037701);
        assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
        assertEq(actualExchangeRate, 1262664164405742069);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase3() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE1;
        _cfg.josephImplementation = address(new ItfJoseph(6, true));
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(180 * TestConstants.N1__0_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding down
        //and then user takes a little bit less stable,
        //so balance in AmmTreasury is little bit higher and finally exchange rate is little bit higher .

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
        _iporProtocol.joseph.itfRedeem(871110090000000999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(actualIpTokenBalanceForUserThree, 316854248781574037701, "incorrect ipToken balance for user three");
        assertEq(
            exchangeRateBeforeProvideLiquidity,
            1262664165103189493,
            "incorrect exchange rate before provide liquidity"
        );
        assertEq(actualExchangeRate, 1262664164102524851, "incorrect exchange rate");
    }
}
