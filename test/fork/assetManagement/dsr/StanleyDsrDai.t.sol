// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../../../contracts/vault/strategies/StrategyDsrDai.sol";
import "../../../../contracts/vault/StanleyDsrDai.sol";
import "../../../../contracts/interfaces/IIpToken.sol";
import "../../../../contracts/interfaces/IStanley.sol";
import "../../../../contracts/interfaces/IJoseph.sol";
import "../../../../contracts/interfaces/IJosephInternal.sol";
import "../../../../contracts/interfaces/IStanleyInternal.sol";
import "../../../../contracts/interfaces/IStrategyDsr.sol";
import "../../../../contracts/interfaces/IStrategyCompound.sol";
import "../../../../contracts/interfaces/IStrategyAave.sol";
import "../../../../contracts/amm/MiltonDai.sol";

contract StanleyAaveDaiTest is Test {
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant sDai = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address public constant ivDai = 0xf93E0edc76f3147C63F53E7eD245330b96009B26;
    address public constant ipDai = 0x8537b194BFf354c4738E9F3C81d67E3371DaDAf8;
    address public constant miltonDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address public constant miltonStorageDai = 0xb99f2a02c0851efdD417bd6935d2eFcd23c56e61;
    address public constant josephDai = 0x086d4daab14741b195deE65aFF050ba184B65045;
    address public constant strategyAaveDai = 0x526d0047725D48BBc6e24C7B82A3e47C1AF1f62f;
    address public constant strategyCompoundDai = 0x87CEF19aCa214d12082E201e6130432Df39fc774;
    address public constant stanleyDai = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;

    address private _iporProtocolOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;

    address internal _admin;
    address internal _user;

    StrategyDsrDai public strategyDsr;

    function setUp() public {
        uint256 forkId = vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _admin = vm.rememberKey(1);
        _user = vm.rememberKey(2);

        strategyDsr = _createDsrStrategy();

        MiltonStorage miltonStorageDaiObj = new MiltonStorage();
        vm.etch(miltonStorageDai, address(miltonStorageDaiObj).code);
    }

    function testShouldBeTheSameBalanceAfterUpgrade() public {
        //given
        IStanley stanley = IStanley(stanleyDai);
        uint256 balanceBefore = stanley.totalBalance(0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523);
        balanceBefore = IporMath.division(balanceBefore, 1e7);

        //when
        _upgradeStanleyDsr();

        //then
        StanleyDsrDai stanleyV2 = StanleyDsrDai(stanleyDai);
        uint256 balanceAfter = stanleyV2.totalBalance(0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523);
        balanceAfter = IporMath.division(balanceAfter, 1e7);

        assertEq(balanceBefore, balanceAfter);
    }

    function testShouldBeTheSameAprAfterUpgrade() public {
        //given
        IStanleyInternal stanley = IStanleyInternal(stanleyDai);

        address strategyAaveBefore = stanley.getStrategyAave();
        address strategyCompoundBefore = stanley.getStrategyCompound();

        uint256 aprAaveBefore = IStrategy(strategyAaveBefore).getApr();
        uint256 aprCompoundBefore = IStrategy(strategyCompoundBefore).getApr();

        //when
        _upgradeStanleyDsr();

        //then
        address strategyAaveAfter = stanley.getStrategyAave();
        address strategyCompoundAfter = stanley.getStrategyCompound();

        uint256 aprAaveAfter = IStrategyDsr(strategyAaveAfter).getApr();
        uint256 aprCompoundAfter = IStrategyDsr(strategyCompoundAfter).getApr();
        uint256 aprDsrAfter = IStrategyDsr(strategyDsr).getApr();

        assertEq(aprAaveBefore, aprAaveAfter);
        assertEq(aprCompoundBefore, aprCompoundAfter);
    }

    function testShouldRebalanceAfterUpgrade() public {
        //given
        IJosephInternal joseph = IJosephInternal(josephDai);
        _upgradeStanleyDsr();

        uint256 aaveApr = IStrategyDsr(strategyAaveDai).getApr();
        uint256 compoundApr = IStrategyDsr(strategyCompoundDai).getApr();
        uint256 dsrApr = IStrategyDsr(strategyDsr).getApr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        //when
        vm.prank(0xA21603c271C6f41CdC83E70a0691171eBB7db40A);
        joseph.rebalance();

        //then
        uint256 balanceDsr = IStrategyDsr(strategyDsr).balanceOf();
        uint256 balanceAave = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 balanceCompound = IStrategyDsr(strategyCompoundDai).balanceOf();
    }

    function testShouldCalculateTheSameExchangeRateAfterUpgrade() public {
        //given
        IStanley stanley = IStanley(stanleyDai);
        uint256 exchangeRateBefore = stanley.calculateExchangeRate();

        //when
        _upgradeStanleyDsr();

        //then
        uint256 exchangeRateAfter = stanley.calculateExchangeRate();
        assertEq(exchangeRateBefore, exchangeRateAfter);
    }

    function testShouldCalculateExchangeRateAfterUpgradeAndProvideLiquidityWithRebalance() public {
        //given
        IStanley stanley = IStanley(stanleyDai);
        uint256 exchangeRateBefore = stanley.calculateExchangeRate();

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 1_000_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(50_000 * 1e18);
        vm.stopPrank();

        //then
        uint256 balanceDsr = IStrategyDsr(strategyDsr).balanceOf();
        uint256 balanceAave = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 balanceCompound = IStrategyDsr(strategyCompoundDai).balanceOf();

        uint256 exchangeRateAfter = stanley.calculateExchangeRate();
        assertEq(exchangeRateBefore, exchangeRateAfter);
    }

    function testShouldProvideAndRedeemFromDsrStrategy() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 1_000_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrBalanceBeforeRedeem = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategyDsr(strategyCompoundDai).balanceOf();

        uint256 ipTokenAmount = IIpToken(ipDai).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);
        //when
        vm.prank(_user);
        joseph.redeem(ipTokenAmount);

        uint256 strategyDsrBalanceAfterRedeem = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategyDsr(strategyCompoundDai).balanceOf();

        assertGt(strategyDsrBalanceBeforeRedeem, strategyDsrBalanceAfterRedeem, "dsr great than");
        assertEq(strategyDsrBalanceAfterRedeem, 0, "dsr zero");

        assertLe(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertLe(
            strategyCompoundBalanceBeforeRedeem,
            strategyCompoundBalanceAfterRedeem,
            "compound"
        );
    }

    function testShouldRedeemFromTwoStrategiesCompoundAndDsr() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        /// @dev first provide trigger rebalance
        joseph.provideLiquidity(70_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        vm.stopPrank();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).unpause();

        uint256 strategyDsrBalanceBeforeRedeem = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategyDsr(strategyCompoundDai).balanceOf();

        uint256 ipTokenAmountBefore = IIpToken(ipDai).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);
        //when
        vm.prank(_user);
        joseph.redeem(ipTokenAmountBefore);

        uint256 ipTokenAmountAfter = IIpToken(ipDai).balanceOf(_user);

        uint256 assetBalanceAfter = IERC20Upgradeable(dai).balanceOf(_user);

        uint256 strategyDsrBalanceAfterRedeem = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategyDsr(strategyCompoundDai).balanceOf();

        assertEq(ipTokenAmountAfter, 0, "ipTokenAmount");

        assertGt(strategyDsrBalanceBeforeRedeem, strategyDsrBalanceAfterRedeem, "dsr great than");
        assertGt(strategyDsrBalanceAfterRedeem, 0, "dsr zero");

        assertLe(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertEq(strategyCompoundBalanceAfterRedeem, 0, "compound");
    }

    function testShouldRedeemFromTwoStrategiesCompoundAndAave() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        /// @dev first provide trigger rebalance
        joseph.provideLiquidity(70_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        vm.stopPrank();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).unpause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).unpause();

        IStrategyDsr(strategyDsr).pause();

        uint256 strategyDsrBalanceBeforeRedeem = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyAaveBalanceBeforeRedeem = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 strategyCompoundBalanceBeforeRedeem = IStrategyDsr(strategyCompoundDai).balanceOf();

        uint256 ipTokenAmountBefore = IIpToken(ipDai).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);
        //when
        vm.prank(_user);
        joseph.redeem(ipTokenAmountBefore);

        uint256 ipTokenAmountAfter = IIpToken(ipDai).balanceOf(_user);

        uint256 strategyDsrBalanceAfterRedeem = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyAaveBalanceAfterRedeem = IStrategyDsr(strategyAaveDai).balanceOf();
        uint256 strategyCompoundBalanceAfterRedeem = IStrategyDsr(strategyCompoundDai).balanceOf();

        assertEq(ipTokenAmountAfter, 0, "ipTokenAmount");

        assertLt(strategyDsrBalanceBeforeRedeem, strategyDsrBalanceAfterRedeem, "dsr great than");
        assertGt(strategyDsrBalanceAfterRedeem, 0, "dsr zero");

        assertGt(strategyAaveBalanceBeforeRedeem, strategyAaveBalanceAfterRedeem, "aave");
        assertGt(
            strategyCompoundBalanceBeforeRedeem,
            strategyCompoundBalanceAfterRedeem,
            "compound"
        );
    }

    function testShouldDepositOnlyInDsrStrategyAndEarnInterest() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrBalanceBefore = IStrategyDsr(strategyDsr).balanceOf();
        uint256 aprBefore = IStrategyDsr(strategyDsr).getApr();

        vm.warp(block.timestamp + 365 days);

        //when
        uint256 strategyDsrBalanceAfter = IStrategyDsr(strategyDsr).balanceOf();

        //then

        uint256 expectedBalanceAndInterest = IporMath.division(
            strategyDsrBalanceBefore +
                IporMath.division(strategyDsrBalanceBefore * aprBefore, 1e18),
            1e7
        );
        uint256 actualBalanceAndInterest = IporMath.division(strategyDsrBalanceAfter, 1e7);

        assertGt(strategyDsrBalanceAfter, strategyDsrBalanceBefore, "dsr great than");
        assertEq(expectedBalanceAndInterest, actualBalanceAndInterest, "dsr apr");
    }

    function testShouldProvideLiquidity() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        uint256 strategyDsrBalanceBefore = IStrategyDsr(strategyDsr).balanceOf();

        //when
        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(70_000 * 1e18);
        vm.stopPrank();

        //then
        uint256 strategyDsrBalanceAfter = IStrategyDsr(strategyDsr).balanceOf();

        assertGt(strategyDsrBalanceAfter, strategyDsrBalanceBefore, "dsr balance");
    }

    function testShouldRedeemLiquidity() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrBalanceBeforeRedeem = IStrategyDsr(strategyDsr).balanceOf();

        uint256 ipTokenAmount = IIpToken(ipDai).balanceOf(_user);

        vm.warp(block.timestamp + 1 days);
        //when
        vm.prank(_user);
        joseph.redeem(ipTokenAmount);

        //then
        uint256 strategyDsrBalanceAfterRedeem = IStrategyDsr(strategyDsr).balanceOf();

        assertGt(strategyDsrBalanceBeforeRedeem, strategyDsrBalanceAfterRedeem, "dsr balance");

        assertEq(strategyDsrBalanceAfterRedeem, 0, "dsr balance zero");
    }

    function testShouldWithdrawFromAllStrategies() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(70_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrBalanceBefore = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyCompoundBalanceBefore = IStrategyCompound(strategyCompoundDai).balanceOf();
        uint256 strategyAaveBalanceBefore = IStrategyAave(strategyAaveDai).balanceOf();
        uint256 ammBalanceBefore = IERC20Upgradeable(dai).balanceOf(address(miltonDai));

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).unpause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).unpause();

        //when
        vm.prank(_iporProtocolOwner);
        IJosephInternal(josephDai).withdrawAllFromStanley();

        //then
        uint256 strategyDsrBalanceAfter = IStrategyDsr(strategyDsr).balanceOf();
        uint256 strategyCompoundBalanceAfter = IStrategyCompound(strategyCompoundDai).balanceOf();
        uint256 strategyAaveBalanceAfter = IStrategyAave(strategyAaveDai).balanceOf();
        uint256 ammBalanceAfter = IERC20Upgradeable(dai).balanceOf(address(miltonDai));

        assertEq(strategyDsrBalanceAfter, 0, "dsr balance");
        assertEq(strategyCompoundBalanceAfter, 0, "compound balance");
        assertEq(strategyAaveBalanceAfter, 0, "aave balance");
        assertGe(
            ammBalanceAfter,
            ammBalanceBefore +
                strategyDsrBalanceBefore +
                strategyCompoundBalanceBefore +
                strategyAaveBalanceBefore,
            "amm balance"
        );
    }

    function testShouldRebalanceToDsrWhenRestIsPaused() public {
        //given
        IStanley stanley = IStanley(stanleyDai);

        _upgradeStanleyDsr();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyAaveDai).pause();

        vm.prank(_iporProtocolOwner);
        IStrategyDsr(strategyCompoundDai).pause();

        deal(address(dai), _user, 100_000e18);

        IJoseph joseph = IJoseph(josephDai);

        vm.startPrank(_user);
        IERC20Upgradeable(dai).approve(address(joseph), type(uint256).max);
        joseph.provideLiquidity(70_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        joseph.provideLiquidity(10_000 * 1e18);
        vm.stopPrank();

        uint256 strategyDsrBalanceBefore = IStrategyDsr(strategyDsr).balanceOf();

        vm.prank(_iporProtocolOwner);
        IJosephInternal(josephDai).addAppointedToRebalance(_user);

        //when
        vm.warp(block.timestamp + 1 days);
        vm.prank(_user);
        IJosephInternal(josephDai).rebalance();

        //then
        uint256 strategyDsrBalanceAfter = IStrategyDsr(strategyDsr).balanceOf();
        assertGe(strategyDsrBalanceAfter, strategyDsrBalanceBefore, "dsr balance");
    }

    function testShouldCloseSwapAndWithdrawFromDsrStrategy() public {}

    //    function testShouldCloseSwapAndWithdrawFromTwoStrategiesIfNeeded() public {}

    function _upgradeStanleyDsr() internal {
        StanleyDsrDai implementation = new StanleyDsrDai(
            dai,
            miltonDai,
            strategyAaveDai,
            strategyCompoundDai,
            address(strategyDsr),
            ivDai
        );

        vm.prank(_iporProtocolOwner);
        UUPSUpgradeable(stanleyDai).upgradeTo(address(implementation));

        /// @dev add allowance for DSR Strategy
        vm.prank(_iporProtocolOwner);
        StanleyDsrDai(stanleyDai).grandMaxAllowanceForSpender(address(dai), address(strategyDsr));
    }

    function _createDsrStrategy() internal returns (StrategyDsrDai) {
        StrategyDsrDai implementation = new StrategyDsrDai(dai, sDai, address(stanleyDai));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        return StrategyDsrDai(address(proxy));
    }
}
