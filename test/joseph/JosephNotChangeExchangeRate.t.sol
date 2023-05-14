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
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

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

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidity18Decimals()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(180 * TestConstants.D18, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            180 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp
        );

        // when
        vm.prank(_userThree);
        _iporProtocol.joseph.itfProvideLiquidity(1500 * TestConstants.D18, block.timestamp);

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(actualIpTokenBalanceForUserThree, 1142857142857142857143);
        assertEq(13125 * TestConstants.D14, exchangeRateBeforeProvideLiquidity);
        assertEq(13125 * TestConstants.D14, actualExchangeRate);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems18Decimals()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _cfg.josephImplementation = address(new MockCase1JosephDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(180 * TestConstants.D18, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            180 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp
        );

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.itfProvideLiquidity(1500 * TestConstants.D18, block.timestamp);
        _iporProtocol.joseph.itfRedeem(874999999999999999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(267857142857142857289, actualIpTokenBalanceForUserThree);
        assertEq(1312500000000000000, exchangeRateBeforeProvideLiquidity);
        assertEq(1312500000000000000, actualExchangeRate);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase1()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _cfg.josephImplementation = address(new MockCase1JosephUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(180 * TestConstants.N1__0_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp
        );

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
        _iporProtocol.joseph.itfRedeem(874999999999999999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(267857142857142857289, actualIpTokenBalanceForUserThree);
        assertEq(1312500000000000000, exchangeRateBeforeProvideLiquidity);
        assertEq(1312500000000000000, actualExchangeRate);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase2()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _cfg.josephImplementation = address(new MockCase1JosephUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(180 * TestConstants.N1__0_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp
        );

        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding up
        //and then user takes a little bit more stable,
        //so balance in Milton is little bit lower and finally exchange rate is little bit lower.

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
        _iporProtocol.joseph.itfRedeem(871111000099999999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(271746142757142857289, actualIpTokenBalanceForUserThree);
        assertEq(1312500000000000000, exchangeRateBeforeProvideLiquidity);
        assertEq(1312499999183722969, actualExchangeRate);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase3()
        public
    {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _cfg.josephImplementation = address(new MockCase1JosephUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(180 * TestConstants.N1__0_6DEC, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.joseph.itfCalculateExchangeRate(
            block.timestamp
        );

        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding down
        //and then user takes a little bit less stable,
        //so balance in Milton is little bit higher and finally exchange rate is little bit higher .

        // when
        vm.startPrank(_userThree);
        _iporProtocol.joseph.itfProvideLiquidity(1500 * TestConstants.N1__0_6DEC, block.timestamp);
        _iporProtocol.joseph.itfRedeem(871110090000000999854, block.timestamp);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.joseph.itfCalculateExchangeRate(block.timestamp);

        assertEq(271747052857141857289, actualIpTokenBalanceForUserThree);
        assertEq(1312500000000000000, exchangeRateBeforeProvideLiquidity);
        assertEq(1312500000276706426, actualExchangeRate);
    }
}
