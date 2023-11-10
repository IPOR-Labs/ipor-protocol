// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../TestForkCommons.sol";

interface IStanleyV1 {
    function totalBalance(address who) external view returns (uint256);

    function getStrategyAave() external view returns (address);

    function getStrategyCompound() external view returns (address);
}

/// @dev Tests verify Asset Management when upgrade from v1 to v2, with assumption that DSR is already deployed
contract ForkAssetManagementDaiTest is TestForkCommons {
    address internal _admin;
    address internal _user;

    function setUp() public {
        /// @dev state of the blockchain: after deploy DSR, before upgrade to V2
        uint256 forkId = vm.createSelectFork(vm.envString("PROVIDER_URL"), 18070400);
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);
    }

    function testShouldBeTheSameBalanceAfterUpgrade() public {
        //given
        IStanleyV1 stanley = IStanleyV1(stanleyProxyDai);
        uint256 balanceBefore = stanley.totalBalance(0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523);
        balanceBefore = IporMath.division(balanceBefore, 1e7);

        //when
        _init();

        //then
        AssetManagementDai assetManagementDai = AssetManagementDai(stanleyProxyDai);
        uint256 balanceAfter = assetManagementDai.totalBalance();
        balanceAfter = IporMath.division(balanceAfter, 1e7);

        assertEq(balanceBefore, balanceAfter);
    }

    function testShouldProvideAndRedeemFromDsrStrategy() public {
        //given
        _init();
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 10, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 1_000_000e18);

        vm.startPrank(_user);

        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBeforeRedeem = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategy(strategyCompoundProxyDai).balanceOf();

        uint256 ipTokenAmount = IIpToken(ipDAI).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);

        //when
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).redeemFromAmmPoolDai(_user, ipTokenAmount);

        uint256 strategyDsrProxyDaiBalanceAfterRedeem = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategy(strategyCompoundProxyDai).balanceOf();

        assertGt(strategyDsrProxyDaiBalanceBeforeRedeem, strategyDsrProxyDaiBalanceAfterRedeem, "dsr great than");

        assertLe(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertLe(strategyCompoundBalanceBeforeRedeem, strategyCompoundBalanceAfterRedeem, "compound");
    }

    function testShouldRedeemFromTwoStrategiesCompoundAndDsr() public {
        //given
        _init();
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        /// @dev first provide trigger rebalance
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        vm.stopPrank();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).unpause();

        uint256 strategyDsrProxyDaiBalanceBeforeRedeem = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategy(strategyCompoundProxyDai).balanceOf();

        uint256 ipTokenAmountBefore = IIpToken(ipDAI).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);

        //when
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).redeemFromAmmPoolDai(_user, ipTokenAmountBefore);

        uint256 ipTokenAmountAfter = IIpToken(ipDAI).balanceOf(_user);

        uint256 assetBalanceAfter = IERC20Upgradeable(DAI).balanceOf(_user);

        uint256 strategyDsrProxyDaiBalanceAfterRedeem = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategy(strategyCompoundProxyDai).balanceOf();

        assertEq(ipTokenAmountAfter, 0, "ipTokenAmount");

        assertGt(strategyDsrProxyDaiBalanceBeforeRedeem, strategyDsrProxyDaiBalanceAfterRedeem, "dsr great than");
        assertGt(strategyDsrProxyDaiBalanceAfterRedeem, 0, "dsr zero");

        assertLe(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertEq(strategyCompoundBalanceAfterRedeem, 0, "compound");
    }

    function testShouldDepositOnlyInDsrStrategyAndEarnInterest() public {
        //given
        _init();

        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 apyBefore = IStrategy(strategyDsrProxyDai).getApy();

        vm.warp(block.timestamp + 365 days);

        //when
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();

        //then

        uint256 expectedBalanceAndInterest = IporMath.division(
            strategyDsrProxyDaiBalanceBefore + IporMath.division(strategyDsrProxyDaiBalanceBefore * apyBefore, 1e18),
            1e7
        );
        uint256 actualBalanceAndInterest = IporMath.division(strategyDsrProxyDaiBalanceAfter, 1e7);

        assertGt(strategyDsrProxyDaiBalanceAfter, strategyDsrProxyDaiBalanceBefore, "dsr great than");
        assertEq(expectedBalanceAndInterest, actualBalanceAndInterest, "dsr apr");
    }

    function testShouldProvideLiquidity() public {
        //given
        _init();
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 1000_000 * 1e18);

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();

        //when
        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();

        assertGt(strategyDsrProxyDaiBalanceAfter, strategyDsrProxyDaiBalanceBefore, "dsr balance");
    }

    function testShouldRedeemLiquidity() public {
        //given
        _init();

        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBeforeRedeem = IStrategy(strategyDsrProxyDai).balanceOf();

        uint256 ipTokenAmount = IIpToken(ipDAI).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);
        //when
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).redeemFromAmmPoolDai(_user, ipTokenAmount);

        //then
        uint256 strategyDsrProxyDaiBalanceAfterRedeem = IStrategy(strategyDsrProxyDai).balanceOf();

        assertGt(strategyDsrProxyDaiBalanceBeforeRedeem, strategyDsrProxyDaiBalanceAfterRedeem, "dsr balance");
    }

    function testShouldWithdrawFromAllStrategies() public {
        //given
        _init();

        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategy(strategyCompoundProxyDai).balanceOf();
        uint256 strategyAaveBalanceBefore = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 ammBalanceBefore = IERC20Upgradeable(DAI).balanceOf(address(ammTreasuryDai));

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).unpause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).unpause();

        vm.warp(block.timestamp + 1 days);

        //when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategy(strategyCompoundProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfter = IStrategy(strategyAaveProxyDai).balanceOf();
        uint256 ammBalanceAfter = IERC20Upgradeable(DAI).balanceOf(address(ammTreasuryDai));

        assertEq(strategyDsrProxyDaiBalanceAfter, 0, "dsr balance");
        assertEq(strategyCompoundBalanceAfter, 0, "compound balance");
        assertEq(strategyAaveBalanceAfter, 0, "aave balance");
        assertGe(
            ammBalanceAfter,
            ammBalanceBefore +
                strategyDsrProxyDaiBalanceBefore +
                strategyCompoundBalanceBefore +
                strategyAaveBalanceBefore,
            "amm balance"
        );
    }

    function testShouldRebalanceToDsrWhenRestIsPaused() public {
        //given
        _init();
        address[] memory pauseGuardians = new address[](1);
        pauseGuardians[0] = owner;

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IIporContractCommonGov(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IIporContractCommonGov(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategy(strategyDsrProxyDai).balanceOf();

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addAppointedToRebalanceInAmm(DAI, _user);

        //when
        vm.warp(block.timestamp + 1 days);
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagement(DAI);

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategy(strategyDsrProxyDai).balanceOf();
        assertGe(strategyDsrProxyDaiBalanceAfter, strategyDsrProxyDaiBalanceBefore, "dsr balance");
    }

//    function testShouldNotCloseSwapAndWithdrawFromDsrStrategyBecauseTwoStrategiesPausedAndNotEnoughCashInAmmAndAm()
//        public
//    {
//        //given
//        _init();
//
//        deal(DAI, _user, 500_000e18);
//        vm.prank(_user);
//        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
//
//        uint256 totalAmount = 100_000 * 1e18;
//
//        vm.startPrank(_user);
//        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
//            _user,
//            totalAmount,
//            1e18,
//            10 * 1e18
//        );
//        vm.stopPrank();
//
//        (uint256 indexValue, , ) = IIporOracle(iporOracleProxy).getIndex(address(DAI));
//
//        vm.prank(owner);
//        IIporOracle(iporOracleProxy).addUpdater(_user);
//
//        vm.prank(_user);
//        IIporOracle(iporOracleProxy).updateIndex(address(DAI), 5e17);
//
//        vm.warp(block.timestamp + 25 days);
//
//        /// @dev Start - prepare strategies in this way that there is not enough cash in AMM and AM
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//
//        address[] memory pauseGuardians = new address[](1);
//        pauseGuardians[0] = owner;
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(pauseGuardians);
//
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 100 * 1e18);
//
//        IIporContractCommonGov(strategyAaveProxyDai).unpause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(
//            DAI,
//            IERC20Upgradeable(DAI).balanceOf(miltonProxyDai) - 2e18
//        );
//
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256[] memory swapPfIds = new uint256[](1);
//        swapPfIds[0] = swapId;
//        uint256[] memory swapRfIds = new uint256[](0);
//
//        //then
//        vm.expectRevert("IPOR_340");
//        vm.prank(_user);
//        //when
//        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(_user, swapPfIds, swapRfIds);
//    }

//    function testShouldCloseSwapAndWithdrawFromDsrStrategyAndCompound() public {
//        //given
//        _init();
//        AmmStorage ammStorage = new AmmStorage(iporProtocolRouterProxy, miltonProxyDai);
//        vm.etch(miltonStorageProxyDai, address(ammStorage).code);
//
//        deal(DAI, _user, 500_000e18);
//        vm.prank(_user);
//        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
//
//        uint256 totalAmount = 100_000 * 1e18;
//
//        vm.startPrank(_user);
//        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
//            _user,
//            totalAmount,
//            1e18,
//            10 * 1e18
//        );
//        vm.stopPrank();
//
//        (uint256 indexValue, , ) = IIporOracle(iporOracleProxy).getIndex(address(DAI));
//
//        vm.prank(owner);
//        IIporOracle(iporOracleProxy).addUpdater(_user);
//
//        vm.prank(_user);
//        IIporOracle(iporOracleProxy).updateIndex(address(DAI), 5e17);
//
//        vm.warp(block.timestamp + 25 days);
//
//        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Compound
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//
//        address[] memory pauseGuardians = new address[](1);
//        pauseGuardians[0] = owner;
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(pauseGuardians);
//
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        /// @dev deposit only to Compound
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//
//        /// @dev deposit only to DSR
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);
//
//        IIporContractCommonGov(strategyAaveProxyDai).unpause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        // @dev most of assets transferred to Aaave
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(
//            DAI,
//            IERC20Upgradeable(DAI).balanceOf(miltonProxyDai) - 2e18
//        );
//
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//        IIporContractCommonGov(strategyCompoundProxyDai).unpause();
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256 strategyDsrProxyDaiBalanceBeforeClose = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceBeforeClose = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        uint256[] memory swapPfIds = new uint256[](1);
//        swapPfIds[0] = swapId;
//        uint256[] memory swapRfIds = new uint256[](0);
//
//        //when
//        vm.prank(_user);
//        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(_user, swapPfIds, swapRfIds);
//
//        //then
//        uint256 strategyDsrProxyDaiBalanceAfterClose = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyCompoundBalanceAfterClose = IStrategy(strategyCompoundProxyDai).balanceOf();
//
//        assertLt(strategyDsrProxyDaiBalanceAfterClose, strategyDsrProxyDaiBalanceBeforeClose, "dsr balance");
//        assertLt(strategyCompoundBalanceAfterClose, strategyCompoundBalanceBeforeClose, "compound balance");
//        assertEq(strategyCompoundBalanceAfterClose, 0, "compound balance zero");
//    }

//    function testShouldCloseSwapAndWithdrawFromDsrStrategyAndAave() public {
//        //given
//        _init();
//
//        deal(DAI, _user, 500_000e18);
//        vm.prank(_user);
//        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
//
//        uint256 totalAmount = 10_000 * 1e18;
//
//        vm.prank(_user);
//        uint256 swapId1 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
//            _user,
//            totalAmount,
//            1e18,
//            10 * 1e18
//        );
//        vm.prank(_user);
//        uint256 swapId2 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
//            _user,
//            totalAmount,
//            1e18,
//            10 * 1e18
//        );
//        vm.prank(_user);
//        uint256 swapId3 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
//            _user,
//            totalAmount,
//            0,
//            10 * 1e18
//        );
//        vm.prank(_user);
//        uint256 swapId4 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
//            _user,
//            totalAmount,
//            0,
//            10 * 1e18
//        );
//
//        (uint256 indexValue, , ) = IIporOracle(iporOracleProxy).getIndex(address(DAI));
//
//        vm.prank(owner);
//        IIporOracle(iporOracleProxy).addUpdater(_user);
//
//        vm.prank(_user);
//        IIporOracle(iporOracleProxy).updateIndex(address(DAI), 5e17);
//
//        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Aave
//        vm.startPrank(owner);
//        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);
//
//        address[] memory pauseGuardians = new address[](1);
//        pauseGuardians[0] = owner;
//        IIporContractCommonGov(strategyAaveProxyDai).addPauseGuardians(pauseGuardians);
//        IIporContractCommonGov(strategyCompoundProxyDai).addPauseGuardians(pauseGuardians);
//        IIporContractCommonGov(strategyDsrProxyDai).addPauseGuardians(pauseGuardians);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        /// @dev deposit only to Aave
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 2 * totalAmount);
//
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//        IIporContractCommonGov(strategyAaveProxyDai).pause();
//
//        /// @dev deposit only to DSR
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 2 * totalAmount);
//
//        IIporContractCommonGov(strategyCompoundProxyDai).unpause();
//        IIporContractCommonGov(strategyDsrProxyDai).pause();
//
//        // @dev most of assets transferred to Compound
//        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(
//            DAI,
//            IERC20Upgradeable(DAI).balanceOf(miltonProxyDai) - 2e18
//        );
//
//        IIporContractCommonGov(strategyAaveProxyDai).unpause();
//        IIporContractCommonGov(strategyCompoundProxyDai).pause();
//        IIporContractCommonGov(strategyDsrProxyDai).unpause();
//
//        vm.stopPrank();
//        /// @dev End - of preparation.
//
//        uint256 strategyDsrProxyDaiBalanceBeforeClose = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceBeforeClose = IStrategy(strategyAaveProxyDai).balanceOf();
//
//        uint256[] memory swapPfIds = new uint256[](2);
//        swapPfIds[0] = swapId1;
//        swapPfIds[1] = swapId2;
//        uint256[] memory swapRfIds = new uint256[](2);
//        swapRfIds[0] = swapId3;
//        swapRfIds[1] = swapId4;
//
//        vm.warp(block.timestamp + 22 days);
//
//        //when
//        vm.prank(_user);
//        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(_user, swapPfIds, swapRfIds);
//
//        //then
//        uint256 strategyDsrProxyDaiBalanceAfterClose = IStrategy(strategyDsrProxyDai).balanceOf();
//        uint256 strategyAaveBalanceAfterClose = IStrategy(strategyAaveProxyDai).balanceOf();
//
//        assertEq(strategyDsrProxyDaiBalanceAfterClose, 0, "dsr balance");
//        assertLt(strategyAaveBalanceAfterClose, strategyAaveBalanceBeforeClose, "aave balance");
//    }
}
