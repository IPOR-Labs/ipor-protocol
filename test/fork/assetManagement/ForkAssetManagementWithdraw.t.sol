// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../TestForkCommons.sol";

contract ForkAssetManagementWithdrawTest is TestForkCommons {
    address internal _admin;
    address internal _user;
    address[] internal _pauseGuardians;

    function setUp() public {
        /// @dev state of the blockchain: after deploy DSR, before upgrade to V2
        uint256 forkId = vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 18560825);
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
        _init();
        _pauseGuardians = new address[](1);
        _pauseGuardians[0] = owner;
    }

    // aave is paused
//    function testShouldWithdrawFromStrategyWithLowestApy() public {
//        //given
//        uint256 totalAmount = 10_000 * 1e18;
//
//        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Aave
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(_pauseGuardians);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        /// @dev deposit only to Aave
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//
//        /// @dev deposit only to DSR
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//        IIporContractCommonGov(strategyCompoundProxyDai).unpause();
//
//        /// @dev deposit only to Compound
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).unpause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceBefore = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceBefore = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        //when
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(DAI, 5_000 * 1e18);
//
//        //then
//        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        assertEq(strategyDsrProxyDaiBalanceBefore, 9999999999999999999999, "strategyDsrProxyDaiBalanceBefore");
//        assertEq(strategyAaveBalanceBefore, 10_000 * 1e18, "strategyAaveBalanceBefore");
//        assertEq(strategyCompoundBalanceBefore, 9999999999999883609072, "strategyCompoundBalanceBefore");
//
//        assertEq(strategyDsrProxyDaiBalanceAfter, 9999999999999956481793, "strategyDsrProxyDaiBalanceAfter");
//        assertEq(strategyAaveBalanceAfter, 10_000 * 1e18, "strategyAaveBalanceAfter");
//        assertEq(strategyCompoundBalanceAfter, 4998999999999927127277, "strategyCompoundBalanceAfter");
//
//        /// @dev Compound with the lowest APY
//        assertLt(IStrategy(strategyCompoundProxyDai).getApy(), IStrategy(strategyAaveProxyDai).getApy());
//        assertLt(IStrategy(strategyCompoundProxyDai).getApy(), IStrategy(strategyDsrProxyDai).getApy());
//    }
// aave is paused
//    function testShouldWithdrawFromStrategyWithLowestApyFromStrategyNotPaused() public {
//        //given
//        uint256 totalAmount = 10_000 * 1e18;
//
//        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Aave
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(_pauseGuardians);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        /// @dev deposit only to Aave
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//
//        /// @dev deposit only to DSR
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//        IIporContractCommonGov(strategyCompoundProxyDai).unpause();
//
//        /// @dev deposit only to Compound
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).unpause();
//
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceBefore = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceBefore = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        //when
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(DAI, 5_000 * 1e18);
//
//        //then
//        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        assertEq(strategyDsrProxyDaiBalanceBefore, 9999999999999999999999);
//        assertEq(strategyAaveBalanceBefore, 10_000 * 1e18);
//        assertEq(strategyCompoundBalanceBefore, 9999999999999883609072);
//
//        assertEq(strategyDsrProxyDaiBalanceAfter, 4998999999999999999998);
//        assertEq(strategyAaveBalanceAfter, 10_000 * 1e18);
//        assertEq(strategyCompoundBalanceAfter, 9999999999999883609072);
//
//        /// @dev Compound with the lowest APY but paused so withdraw from DSR
//        assertLt(IStrategy(strategyCompoundProxyDai).getApy(), IStrategy(strategyAaveProxyDai).getApy());
//        assertLt(IStrategy(strategyCompoundProxyDai).getApy(), IStrategy(strategyDsrProxyDai).getApy());
//    }
// aave is paused
//    function testShouldWithdrawFromMoreThanOneStrategy() public {
//        //given
//        uint256 totalAmount = 10_000 * 1e18;
//
//        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Aave
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(_pauseGuardians);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        /// @dev deposit only to Aave
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//
//        /// @dev deposit only to DSR
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).unpause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceBefore = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceBefore = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        //when
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(DAI, 15_000 * 1e18);
//
//        //then
//        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        assertEq(strategyDsrProxyDaiBalanceBefore, 9999999999999999999999);
//        assertEq(strategyAaveBalanceBefore, 10000 * 1e18);
//        assertEq(strategyCompoundBalanceBefore, 0);
//
//        assertEq(strategyDsrProxyDaiBalanceAfter, 0);
//        assertEq(strategyAaveBalanceAfter, 4998999999999999999999);
//        assertEq(strategyCompoundBalanceAfter, 0);
//    }

    // aave is paused
//    function testShouldWithdrawFromAaveButAaveHasMaxApy() public {
//        //given
//        uint256 totalAmount = 10_000 * 1e18;
//
//        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Aave
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(_pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(_pauseGuardians);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        /// @dev deposit only to Aave
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyCompoundProxyDai).unpause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceBefore = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceBefore = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        //when
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(DAI, 10_000 * 1e18);
//
//        //then
//        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        assertEq(strategyDsrProxyDaiBalanceBefore, 0);
//        assertEq(strategyAaveBalanceBefore, 10000 * 1e18);
//        assertEq(strategyCompoundBalanceBefore, 0);
//
//        assertEq(strategyDsrProxyDaiBalanceAfter, 0);
//        assertEq(strategyAaveBalanceAfter, 0);
//        assertEq(strategyCompoundBalanceAfter, 0);
//
//        assertLt(IStrategy(strategyDsrProxyDai).getApy(), IStrategy(strategyAaveProxyDai).getApy());
//        assertLt(IStrategy(strategyDsrProxyDai).getApy(), IStrategy(strategyAaveProxyDai).getApy());
//    }

    function testShouldWithdrawAllDAI() public {
        //when
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
        vm.stopPrank();

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyDai).balanceOf();

        assertEq(strategyDsrProxyDaiBalanceAfter, 0);
        assertEq(strategyAaveBalanceAfter, 0);
        assertEq(strategyCompoundBalanceAfter, 0);
    }

    function testShouldWithdrawAllUsdt() public {
        //when
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(USDT);
        vm.stopPrank();

        //then
        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyUsdt).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyUsdt).balanceOf();

        assertEq(strategyAaveBalanceAfter, 0, "strategyAaveBalanceAfter");
        assertLt(strategyCompoundBalanceAfter, 1e12, "strategyCompoundBalanceAfter");
    }

    function testShouldWithdrawAllUsdc() public {
        //when
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(USDC);
        vm.stopPrank();

        //then
        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyUsdc).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyUsdc).balanceOf();

        assertEq(strategyAaveBalanceAfter, 0, "strategyAaveBalanceAfter");
        assertLt(strategyCompoundBalanceAfter, 1e12, "strategyCompoundBalanceAfter");
    }

    function testShouldReturnRewardsStrategyAaveUsdc() public {
        //when
        uint256 rewards = AaveIncentivesInterface(StrategyAave(strategyAaveProxyUsdc).aaveIncentive())
            .getUserUnclaimedRewards(strategyAaveProxyUsdc);
        //then
        assertEq(rewards, 0, "rewards");
    }

    function testShouldReturnRewardsStrategyAaveUsdt() public {
        //when
        uint256 rewards = AaveIncentivesInterface(StrategyAave(strategyAaveProxyUsdt).aaveIncentive())
            .getUserUnclaimedRewards(strategyAaveProxyUsdt);
        //then
        assertEq(rewards, 0, "rewards");
    }

    function testShouldReturnRewardsStrategyAaveDai() public {
        //when
        uint256 rewards = AaveIncentivesInterface(StrategyAave(strategyAaveProxyDai).aaveIncentive())
            .getUserUnclaimedRewards(strategyAaveProxyDai);
        //then
        assertEq(rewards, 0, "rewards");
    }

    function testShouldReturnRewardsCompoundDai() public {
        //given
        IERC20Upgradeable compToken = StrategyCompound(strategyCompoundProxyDai).compToken();

        vm.startPrank(owner);
        StrategyCompound(strategyCompoundProxyDai).setTreasuryManager(owner);
        StrategyCompound(strategyCompoundProxyDai).setTreasury(owner);
        vm.stopPrank();

        uint256 compTokenBalanceBefore = compToken.balanceOf(owner);

        //when
        vm.prank(owner);
        StrategyCompound(strategyCompoundProxyDai).doClaim();

        //then
        uint256 compTokenBalanceAfter = compToken.balanceOf(owner);

        assertGt(compTokenBalanceAfter, compTokenBalanceBefore, "compTokenBalanceAfter");
        assertEq(compTokenBalanceAfter, 47440093174178130640, "compTokenBalanceAfter");
    }

    function testShouldReturnRewardsCompoundUsdt() public {
        //given
        IERC20Upgradeable compToken = StrategyCompound(strategyCompoundProxyUsdt).compToken();

        vm.startPrank(owner);
        StrategyCompound(strategyCompoundProxyUsdt).setTreasuryManager(owner);
        StrategyCompound(strategyCompoundProxyUsdt).setTreasury(owner);
        vm.stopPrank();

        uint256 compTokenBalanceBefore = compToken.balanceOf(owner);

        //when
        vm.prank(owner);
        StrategyCompound(strategyCompoundProxyUsdt).doClaim();

        //then
        uint256 compTokenBalanceAfter = compToken.balanceOf(owner);

        assertEq(compTokenBalanceAfter, compTokenBalanceBefore, "compTokenBalanceAfter");
        assertEq(compTokenBalanceAfter, 0, "compTokenBalanceAfter");
    }

    function testShouldReturnRewardsCompoundUsdc() public {
        //given
        IERC20Upgradeable compToken = StrategyCompound(strategyCompoundProxyUsdc).compToken();

        vm.startPrank(owner);
        StrategyCompound(strategyCompoundProxyUsdc).setTreasuryManager(owner);
        StrategyCompound(strategyCompoundProxyUsdc).setTreasury(owner);
        vm.stopPrank();

        uint256 compTokenBalanceBefore = compToken.balanceOf(owner);

        //when
        vm.prank(owner);
        StrategyCompound(strategyCompoundProxyUsdc).doClaim();

        //then
        uint256 compTokenBalanceAfter = compToken.balanceOf(owner);

        assertGt(compTokenBalanceAfter, compTokenBalanceBefore, "compTokenBalanceAfter");
        assertEq(compTokenBalanceAfter, 45438721644038757782, "compTokenBalanceAfter");
    }
}
