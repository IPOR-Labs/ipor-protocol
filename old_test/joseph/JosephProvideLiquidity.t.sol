// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/interfaces/types/IporTypes.sol";
import "contracts/libraries/Constants.sol";

contract JosephProvideLiquidity is TestCommons, DataUtils, SwapUtils {
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

    function testShouldSetupInitValueForRedeemLPMaxUtilizationPercentageUSDT() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        uint256 actualValue = _iporProtocol.joseph.getRedeemLpMaxUtilizationRate();

        // then
        assertEq(actualValue, TestConstants.D18);
    }

    function testShouldSetupInitValueForRedeemLPMaxUtilizationPercentageUSDC() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        uint256 actualValue = _iporProtocol.joseph.getRedeemLpMaxUtilizationRate();

        // then
        assertEq(actualValue, TestConstants.D18);
    }

    function testShouldSetupInitValueForRedeemLPMaxUtilizationPercentageDAI() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        uint256 actualValue = _iporProtocol.joseph.getRedeemLpMaxUtilizationRate();

        // then
        assertEq(actualValue, TestConstants.D18);
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And18Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_14_000_18DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammTreasury.getAccruedBalance();

        // then
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000 * TestConstants.D18, _iporProtocol.asset.balanceOf(_liquidityProvider));
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And6Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_14_000_6DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammTreasury.getAccruedBalance();

        // then
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_6DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000000000, _iporProtocol.asset.balanceOf(_liquidityProvider));
    }

    function testShouldNotProvideLiquidityWhenLiquidyPoolIsEmpty() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        _iporProtocol.ammStorage.setJoseph(_userOne);
        vm.prank(_userOne);
        _iporProtocol.ammStorage.subtractLiquidity(TestConstants.USD_10_000_18DEC);
        _iporProtocol.ammStorage.setJoseph(address(_iporProtocol.joseph));

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.setMaxLiquidityPoolBalance(20000);
        _iporProtocol.joseph.setMaxLpAccountContribution(15000);
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_15_000_18DEC, block.timestamp);

        // when other user provides liquidity
        vm.prank(_userOne);
        vm.expectRevert("IPOR_304");
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_15_000_18DEC, block.timestamp);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.setMaxLiquidityPoolBalance(2000000);
        _iporProtocol.joseph.setMaxLpAccountContribution(50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.joseph.itfProvideLiquidity(51000 * TestConstants.D18, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase2() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.setMaxLiquidityPoolBalance(2000000);
        _iporProtocol.joseph.setMaxLpAccountContribution(50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase3() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.setMaxLiquidityPoolBalance(2000000);
        _iporProtocol.joseph.setMaxLpAccountContribution(50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_50_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase4() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.setMaxLiquidityPoolBalance(2000000);
        _iporProtocol.joseph.setMaxLpAccountContribution(50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);

        _iporProtocol.ipToken.transfer(_userThree, TestConstants.USD_50_000_18DEC);

        uint256 ipTokenLiquidityProviderBalance = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(ipTokenLiquidityProviderBalance, TestConstants.ZERO);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_18DEC);
        vm.stopPrank();
    }
}
