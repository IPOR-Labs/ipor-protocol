// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/tokens/IpToken.sol";

contract AmmPoolsNotExchangeRate is TestCommons {
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
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE0;
        _cfg.openSwapServiceTestCase = BuilderUtils.AmmOpenSwapServiceTestCase.CASE1;
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidity18Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC));

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 180 * TestConstants.D18);

                AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 6553500000000000000,
            maxCollateralRatioPerLeg: 6553500000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            180 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );

        // when
        vm.prank(_userThree);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_userThree, 1500 * TestConstants.D18);

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        assertEq(actualIpTokenBalanceForUserThree, 1499712450089551257107);
        assertEq(exchangeRateBeforeProvideLiquidity, 1000191736696212379);
        assertEq(actualExchangeRate, 1000191736696212379);
    }

    function testShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems18Decimals() public {
        // given
        _cfg.poolsServiceTestCase = BuilderUtils.AmmPoolsServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC));

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 180 * TestConstants.D18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 6553500000000000000,
            maxCollateralRatioPerLeg: 6553500000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );


    vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            180 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_userThree, 1500 * TestConstants.D18);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_userThree, 874999999999999999854);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        assertEq(actualIpTokenBalanceForUserThree, 624712450089551257253);
        assertEq(exchangeRateBeforeProvideLiquidity, 1000191736696212379);
        assertEq(actualExchangeRate, 1000191736696212379);
    }

    function skipTestShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase1()
        public
    {
        // given
        _cfg.poolsServiceTestCase = BuilderUtils.AmmPoolsServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC));

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 180 * TestConstants.N1__0_6DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userThree, 1500 * TestConstants.N1__0_6DEC);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolUsdt(_userThree, 874999999999999999854);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        assertEq(actualIpTokenBalanceForUserThree, 312964338781575037701);
        assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
        assertEq(actualExchangeRate, 1262664166047052506);
    }

    function skipTestShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase2()
        public
    {
        // given
        _cfg.poolsServiceTestCase = BuilderUtils.AmmPoolsServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC));

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 180 * TestConstants.N1__0_6DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );

        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding up
        //and then user takes a little bit more stable,
        //so balance in AmmTreasury is little bit lower and finally exchange rate is little bit lower.

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userThree, 1500 * TestConstants.N1__0_6DEC);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolUsdt(_userThree, 871111000099999999854);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        assertEq(actualIpTokenBalanceForUserThree, 316853338681575037701);
        assertEq(exchangeRateBeforeProvideLiquidity, 1262664165103189493);
        assertEq(actualExchangeRate, 1262664164405742069);
    }

    function skipTestShouldNotChangeExchangeRateWhenLiquidityProviderProvidesLiquidityAndRedeems6DecimalsCase3()
        public
    {
        // given
        _cfg.poolsServiceTestCase = BuilderUtils.AmmPoolsServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC));

        vm.prank(_liquidityProvider);
        _iporProtocol.iporOracle.updateIndexes(getIndexToUpdate(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC));

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            180 * TestConstants.N1__0_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        uint256 exchangeRateBeforeProvideLiquidity = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(
            address(_iporProtocol.asset)
        );

        //Redeemed amount represented in 18 decimals after conversion to 6 decimals makes rounding down
        //and then user takes a little bit less stable,
        //so balance in AmmTreasury is little bit higher and finally exchange rate is little bit higher .

        // when
        vm.startPrank(_userThree);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_userThree, 1500 * TestConstants.N1__0_6DEC);
        _iporProtocol.ammPoolsService.redeemFromAmmPoolUsdt(_userThree, 871110090000000999854);
        vm.stopPrank();

        // then
        uint256 actualIpTokenBalanceForUserThree = _iporProtocol.ipToken.balanceOf(_userThree);
        uint256 actualExchangeRate = _iporProtocol.ammPoolsLens.getIpTokenExchangeRate(address(_iporProtocol.asset));

        assertEq(actualIpTokenBalanceForUserThree, 316854248781574037701, "incorrect ipToken balance for user three");
        assertEq(
            exchangeRateBeforeProvideLiquidity,
            1262664165103189493,
            "incorrect exchange rate before provide liquidity"
        );
        assertEq(actualExchangeRate, 1262664164102524851, "incorrect exchange rate");
    }
}
