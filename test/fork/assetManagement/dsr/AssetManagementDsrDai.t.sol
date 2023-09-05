// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
//import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../TestForkCommons.sol";

//import "../../../../contracts/vault/strategies/StrategyDsrDai.sol";
//import "../../../../contracts/vault/StanleyDsrDai.sol";
//import "../../../../contracts/interfaces/IIpToken.sol";
//import "../../../../contracts/interfaces/IStanley.sol";
//import "../../../../contracts/interfaces/IJosephInternal.sol";
//import "../../../../contracts/interfaces/IStanleyInternal.sol";
//import "../../../../contracts/interfaces/IStrategyDsr.sol";
//import "../../../../contracts/interfaces/IStrategyCompound.sol";
//import "../../../../contracts/interfaces/IStrategyAave.sol";
//import "../../../../contracts/interfaces/IIporOracle.sol";
//import "../../../../contracts/amm/miltonProxyDai.sol";
//import "../../../../contracts/amm/pool/Joseph.sol";
//import "../../../../contracts/mocks/milton/MockCase0miltonProxyDai.sol";

interface IStanleyV1 {
    function totalBalance(address who) external view returns (uint256);

    function getStrategyAave() external view returns (address);

    function getStrategyCompound() external view returns (address);
}

interface IStrategyV1 {
    function getApr() external view returns (uint256);
}

/// @dev Tests verify Asset Management when upgrade from v1 to v2, with assumption that DSR is already deployed
contract AssetManagementDsrDaiTest is TestForkCommons {
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

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 10, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 1_000_000e18);

        vm.startPrank(_user);

        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBeforeRedeem = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategyDsr(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategyDsr(strategyCompoundProxyDai).balanceOf();

        uint256 ipTokenAmount = IIpToken(ipDAI).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);

        //when
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).redeemFromAmmPoolDai(_user, ipTokenAmount);

        uint256 strategyDsrProxyDaiBalanceAfterRedeem = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategyDsr(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategyDsr(strategyCompoundProxyDai).balanceOf();

        assertGt(strategyDsrProxyDaiBalanceBeforeRedeem, strategyDsrProxyDaiBalanceAfterRedeem, "dsr great than");

        assertLe(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertLe(strategyCompoundBalanceBeforeRedeem, strategyCompoundBalanceAfterRedeem, "compound");
    }

    function testShouldRedeemFromTwoStrategiesCompoundAndDsr() public {
        //given
        _init();

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

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
        IStrategyDsr(strategyCompoundProxyDai).unpause();

        uint256 strategyDsrProxyDaiBalanceBeforeRedeem = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategyDsr(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategyDsr(strategyCompoundProxyDai).balanceOf();

        uint256 ipTokenAmountBefore = IIpToken(ipDAI).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);

        //when
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).redeemFromAmmPoolDai(_user, ipTokenAmountBefore);

        uint256 ipTokenAmountAfter = IIpToken(ipDAI).balanceOf(_user);

        uint256 assetBalanceAfter = IERC20Upgradeable(DAI).balanceOf(_user);

        uint256 strategyDsrProxyDaiBalanceAfterRedeem = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategyDsr(strategyAaveProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategyDsr(strategyCompoundProxyDai).balanceOf();

        assertEq(ipTokenAmountAfter, 0, "ipTokenAmount");

        assertGt(strategyDsrProxyDaiBalanceBeforeRedeem, strategyDsrProxyDaiBalanceAfterRedeem, "dsr great than");
        assertGt(strategyDsrProxyDaiBalanceAfterRedeem, 0, "dsr zero");

        assertLe(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertEq(strategyCompoundBalanceAfterRedeem, 0, "compound");
    }

    function testShouldDepositOnlyInDsrStrategyAndEarnInterest() public {
        //given
        _init();

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 apyBefore = IStrategyDsr(strategyDsrProxyDai).getApy();

        vm.warp(block.timestamp + 365 days);

        //when
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategyDsr(strategyDsrProxyDai).balanceOf();

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

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 1000_000 * 1e18);

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategyDsr(strategyDsrProxyDai).balanceOf();

        //when
        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategyDsr(strategyDsrProxyDai).balanceOf();

        assertGt(strategyDsrProxyDaiBalanceAfter, strategyDsrProxyDaiBalanceBefore, "dsr balance");
    }

    function testShouldRedeemLiquidity() public {
        //given
        _init();

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBeforeRedeem = IStrategyDsr(strategyDsrProxyDai).balanceOf();

        uint256 ipTokenAmount = IIpToken(ipDAI).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);
        //when
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).redeemFromAmmPoolDai(_user, ipTokenAmount);

        //then
        uint256 strategyDsrProxyDaiBalanceAfterRedeem = IStrategyDsr(strategyDsrProxyDai).balanceOf();

        assertGt(strategyDsrProxyDaiBalanceBeforeRedeem, strategyDsrProxyDaiBalanceAfterRedeem, "dsr balance");
    }

    function testShouldWithdrawFromAllStrategies() public {
        //given
        _init();

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategyDsr(strategyCompoundProxyDai).balanceOf();
        uint256 strategyAaveBalanceBefore = IStrategyDsr(strategyAaveProxyDai).balanceOf();
        uint256 ammBalanceBefore = IERC20Upgradeable(DAI).balanceOf(address(miltonProxyDai));

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).unpause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).unpause();

        vm.warp(block.timestamp + 1 days);

        //when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategyDsr(strategyCompoundProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfter = IStrategyDsr(strategyAaveProxyDai).balanceOf();
        uint256 ammBalanceAfter = IERC20Upgradeable(DAI).balanceOf(address(miltonProxyDai));

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

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(DAI, type(uint32).max, 50, 500);

        vm.prank(owner);
        IStrategyDsr(strategyAaveProxyDai).pause();

        vm.prank(owner);
        IStrategyDsr(strategyCompoundProxyDai).pause();

        deal(address(DAI), _user, 100_000e18);

        vm.startPrank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 70_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        IAmmPoolsService(iporProtocolRouterProxy).provideLiquidityDai(_user, 10_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrProxyDaiBalanceBefore = IStrategyDsr(strategyDsrProxyDai).balanceOf();

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addAppointedToRebalanceInAmm(DAI, _user);

        //when
        vm.warp(block.timestamp + 1 days);
        vm.prank(_user);
        IAmmPoolsService(iporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagement(DAI);

        //then
        uint256 strategyDsrProxyDaiBalanceAfter = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        assertGe(strategyDsrProxyDaiBalanceAfter, strategyDsrProxyDaiBalanceBefore, "dsr balance");
    }

    function testShouldNotCloseSwapAndWithdrawFromDsrStrategyBecauseTwoStrategiesPausedAndNotEnoughCashInAmmAndAm()
        public
    {
        //given
        _init();

        deal(DAI, _user, 500_000e18);
        vm.prank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);

        uint256 totalAmount = 100_000 * 1e18;

        vm.startPrank(_user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            _user,
            totalAmount,
            1e18,
            10 * 1e18
        );
        vm.stopPrank();

        (uint256 indexValue, , ) = IIporOracle(iporOracleProxy).getIndex(address(DAI));

        vm.prank(owner);
        IIporOracle(iporOracleProxy).addUpdater(_user);

        vm.prank(_user);
        IIporOracle(iporOracleProxy).updateIndex(address(DAI), 5e17);

        vm.warp(block.timestamp + 25 days);

        /// @dev Start - prepare strategies in this way that there is not enough cash in AMM and AM
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);

        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);
        IStrategyDsr(strategyDsrProxyDai).addPauseGuardian(owner);

        IStrategyDsr(strategyAaveProxyDai).pause();
        IStrategyDsr(strategyCompoundProxyDai).pause();

        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 100 * 1e18);

        IStrategyDsr(strategyAaveProxyDai).unpause();
        IStrategyDsr(strategyDsrProxyDai).pause();

        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(
            DAI,
            IERC20Upgradeable(DAI).balanceOf(miltonProxyDai) - 2e18
        );

        IStrategyDsr(strategyAaveProxyDai).pause();
        IStrategyDsr(strategyDsrProxyDai).unpause();

        vm.stopPrank();
        /// @dev End - of preparation.

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        //then
        vm.expectRevert("IPOR_340");
        vm.prank(_user);
        //when
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(_user, swapPfIds, swapRfIds);
    }

    function testShouldCloseSwapAndWithdrawFromDsrStrategyAndCompound() public {
        //given
        _init();
        AmmStorage ammStorage = new AmmStorage(iporProtocolRouterProxy, miltonProxyDai);
        vm.etch(miltonStorageProxyDai, address(ammStorage).code);

        deal(DAI, _user, 500_000e18);
        vm.prank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);

        uint256 totalAmount = 100_000 * 1e18;

        vm.startPrank(_user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            _user,
            totalAmount,
            1e18,
            10 * 1e18
        );
        vm.stopPrank();

        (uint256 indexValue, , ) = IIporOracle(iporOracleProxy).getIndex(address(DAI));

        vm.prank(owner);
        IIporOracle(iporOracleProxy).addUpdater(_user);

        vm.prank(_user);
        IIporOracle(iporOracleProxy).updateIndex(address(DAI), 5e17);

        vm.warp(block.timestamp + 25 days);

        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Compound
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);

        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);
        IStrategyDsr(strategyDsrProxyDai).addPauseGuardian(owner);

        IStrategyDsr(strategyAaveProxyDai).pause();
        IStrategyDsr(strategyDsrProxyDai).pause();

        /// @dev deposit only to Compound
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);

        IStrategyDsr(strategyDsrProxyDai).unpause();
        IStrategyDsr(strategyCompoundProxyDai).pause();

        /// @dev deposit only to DSR
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, totalAmount);

        IStrategyDsr(strategyAaveProxyDai).unpause();
        IStrategyDsr(strategyDsrProxyDai).pause();

        // @dev most of assets transferred to Aaave
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(
            DAI,
            IERC20Upgradeable(DAI).balanceOf(miltonProxyDai) - 2e18
        );

        IStrategyDsr(strategyAaveProxyDai).pause();
        IStrategyDsr(strategyCompoundProxyDai).unpause();
        IStrategyDsr(strategyDsrProxyDai).unpause();

        vm.stopPrank();
        /// @dev End - of preparation.

        uint256 strategyDsrProxyDaiBalanceBeforeClose = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeClose = IStrategyDsr(strategyCompoundProxyDai).balanceOf();

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        //when
        vm.prank(_user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(_user, swapPfIds, swapRfIds);

        //then
        uint256 strategyDsrProxyDaiBalanceAfterClose = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyCompoundBalanceAfterClose = IStrategyDsr(strategyCompoundProxyDai).balanceOf();

        assertLt(strategyDsrProxyDaiBalanceAfterClose, strategyDsrProxyDaiBalanceBeforeClose, "dsr balance");
        assertLt(strategyCompoundBalanceAfterClose, strategyCompoundBalanceBeforeClose, "compound balance");
        assertEq(strategyCompoundBalanceAfterClose, 0, "compound balance zero");
    }

    function testShouldCloseSwapAndWithdrawFromDsrStrategyAndAave() public {
        //given
        _init();

        deal(DAI, _user, 500_000e18);
        vm.prank(_user);
        IERC20Upgradeable(DAI).approve(address(iporProtocolRouterProxy), type(uint256).max);

        uint256 totalAmount = 10_000 * 1e18;

        vm.prank(_user);
        uint256 swapId1 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            _user,
            totalAmount,
            1e18,
            10 * 1e18
        );
        vm.prank(_user);
        uint256 swapId2 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            _user,
            totalAmount,
            1e18,
            10 * 1e18
        );
        vm.prank(_user);
        uint256 swapId3 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
            _user,
            totalAmount,
            0,
            10 * 1e18
        );
        vm.prank(_user);
        uint256 swapId4 = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed28daysDai(
            _user,
            totalAmount,
            0,
            10 * 1e18
        );

        (uint256 indexValue, , ) = IIporOracle(iporOracleProxy).getIndex(address(DAI));

        vm.prank(owner);
        IIporOracle(iporOracleProxy).addUpdater(_user);

        vm.prank(_user);
        IIporOracle(iporOracleProxy).updateIndex(address(DAI), 5e17);

        /// @dev Start - prepare strategies in this way that there part of cash in DSR and Aave
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(DAI);

        IStrategyDsr(strategyAaveProxyDai).addPauseGuardian(owner);
        IStrategyDsr(strategyCompoundProxyDai).addPauseGuardian(owner);
        IStrategyDsr(strategyDsrProxyDai).addPauseGuardian(owner);

        IStrategyDsr(strategyCompoundProxyDai).pause();
        IStrategyDsr(strategyDsrProxyDai).pause();

        /// @dev deposit only to Aave
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 2 * totalAmount);

        IStrategyDsr(strategyDsrProxyDai).unpause();
        IStrategyDsr(strategyAaveProxyDai).pause();

        /// @dev deposit only to DSR
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(DAI, 2 * totalAmount);

        IStrategyDsr(strategyCompoundProxyDai).unpause();
        IStrategyDsr(strategyDsrProxyDai).pause();

        // @dev most of assets transferred to Compound
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(
            DAI,
            IERC20Upgradeable(DAI).balanceOf(miltonProxyDai) - 2e18
        );

        IStrategyDsr(strategyAaveProxyDai).unpause();
        IStrategyDsr(strategyCompoundProxyDai).pause();
        IStrategyDsr(strategyDsrProxyDai).unpause();

        vm.stopPrank();
        /// @dev End - of preparation.

        uint256 strategyDsrProxyDaiBalanceBeforeClose = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceBeforeClose = IStrategyDsr(strategyAaveProxyDai).balanceOf();

        uint256[] memory swapPfIds = new uint256[](2);
        swapPfIds[0] = swapId1;
        swapPfIds[1] = swapId2;
        uint256[] memory swapRfIds = new uint256[](2);
        swapRfIds[0] = swapId3;
        swapRfIds[1] = swapId4;

        vm.warp(block.timestamp + 22 days);

        //when
        vm.prank(_user);
        IAmmCloseSwapService(iporProtocolRouterProxy).closeSwapsDai(_user, swapPfIds, swapRfIds);

        //then
        uint256 strategyDsrProxyDaiBalanceAfterClose = IStrategyDsr(strategyDsrProxyDai).balanceOf();
        uint256 strategyAaveBalanceAfterClose = IStrategyDsr(strategyAaveProxyDai).balanceOf();

        assertEq(strategyDsrProxyDaiBalanceAfterClose, 0, "dsr balance");
        assertLt(strategyAaveBalanceAfterClose, strategyAaveBalanceBeforeClose, "aave balance");
    }
}
