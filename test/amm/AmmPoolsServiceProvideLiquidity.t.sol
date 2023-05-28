// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
//import {DataUtils} from "../utils/DataUtils.sol";
//import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/interfaces/types/IporTypes.sol";
import "contracts/libraries/Constants.sol";

contract AmmPoolsServiceProvideLiquidity is TestCommons {
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

    function testShouldProvideLiquidityAndTakeIpTokenWhenSimpleCase1And18Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_14_000_18DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getBalance(
            address(_iporProtocol.asset)
        );

        // then
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000 * TestConstants.D18, _iporProtocol.asset.balanceOf(_liquidityProvider));
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And6Decimals() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_14_000_6DEC);
        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getBalance(
            address(_iporProtocol.asset)
        );

        // then
        assertEq(TestConstants.USD_14_000_18DEC, _iporProtocol.ipToken.balanceOf(_liquidityProvider));
        assertEq(TestConstants.USD_14_000_6DEC, _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury)));
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000000000, _iporProtocol.asset.balanceOf(_liquidityProvider));
    }

    function testShouldNotProvideLiquidityWhenLiquidityPoolIsEmpty() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidity(TestConstants.USD_10_000_18DEC);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmMaxLiquidityPoolBalance(address(_iporProtocol.asset), 20000);
        _iporProtocol.ammGovernanceService.setAmmMaxLpAccountContribution(address(_iporProtocol.asset), 15000);
        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_15_000_18DEC);

        // when other user provides liquidity
        vm.prank(_userOne);
        vm.expectRevert("IPOR_304");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_15_000_18DEC);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase1() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmMaxLiquidityPoolBalance(address(_iporProtocol.asset), 2000000);
        _iporProtocol.ammGovernanceService.setAmmMaxLpAccountContribution(address(_iporProtocol.asset), 50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 51000 * TestConstants.D18);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase2() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmMaxLiquidityPoolBalance(address(_iporProtocol.asset), 2000000);
        _iporProtocol.ammGovernanceService.setAmmMaxLpAccountContribution(address(_iporProtocol.asset), 50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase3() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmMaxLiquidityPoolBalance(address(_iporProtocol.asset), 2000000);
        _iporProtocol.ammGovernanceService.setAmmMaxLpAccountContribution(address(_iporProtocol.asset), 50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);
        _iporProtocol.ammPoolsService.redeemDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase4() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammGovernanceService.setAmmMaxLiquidityPoolBalance(address(_iporProtocol.asset), 2000000);
        _iporProtocol.ammGovernanceService.setAmmMaxLpAccountContribution(address(_iporProtocol.asset), 50000);

        vm.startPrank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);

        _iporProtocol.ipToken.transfer(_userThree, TestConstants.USD_50_000_18DEC);

        uint256 ipTokenLiquidityProviderBalance = _iporProtocol.ipToken.balanceOf(_liquidityProvider);
        assertEq(ipTokenLiquidityProviderBalance, TestConstants.ZERO);

        // when
        vm.expectRevert("IPOR_305");
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_50_000_18DEC);
        vm.stopPrank();
    }
}