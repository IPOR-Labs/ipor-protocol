// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@ipor-protocol/test/TestCommons.sol";
import "../utils/TestConstants.sol";
import "@ipor-protocol/contracts/tokens/IpToken.sol";
import "@ipor-protocol/contracts/interfaces/types/IporTypes.sol";

contract AmmPoolsExchangeRateLiquidityTest is TestCommons {
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
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceAndIpTokenTotalSupplyIsZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsNotZeroAnd18Decimals()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsNotZeroAnd6Decimals()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_14_000_6DEC);

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsZeroAndIpTokenTotalSupplyIsNotZeroAnd18Decimals()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
        vm.stopPrank();

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, TestConstants.ZERO);
    }

    function testShouldCalculateExchangeRateWhenExchangeRateIsGreaterThan1And18Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 40 * TestConstants.D18);

        // open position to have something in the pool
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            40 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, 1000951604132680805);
    }

    function testShouldCalculateExchangeRateWhenLiquidityPoolBalanceIsNotZeroAndIpTokenTotalSupplyIsZeroAnd18Decimals()
        public
    {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC
        );

        //BEGIN HACK - provide liquidity without mint ipToken
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.addLiquidityInternal(
            _liquidityProvider,
            TestConstants.USD_2_000_18DEC,
            TestConstants.USD_20_000_000_18DEC,
            TestConstants.USD_10_000_000_18DEC
        );
        vm.stopPrank();
        vm.startPrank(address(_liquidityProvider));
        _iporProtocol.asset.transfer(address(_iporProtocol.ammTreasury), TestConstants.USD_2_000_18DEC);
        vm.stopPrank();
        //END HACK - provide liquidity without mint ipToken

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(_iporProtocol.asset.balanceOf(address(_iporProtocol.ipToken)), TestConstants.ZERO);
        assertGt(balance.liquidityPool, TestConstants.ZERO);
        assertEq(actualExchangeRate, TestConstants.D18);
    }

    function testShouldCalculateExchangeRateWhenExchangeRateIsGreaterThan1And6Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 40 * TestConstants.N1__0_6DEC);

        // open position to have something in the pool
        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            40 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        // then
        assertEq(actualExchangeRate, 1000951604132680805);
    }
}
