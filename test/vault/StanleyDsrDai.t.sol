// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../TestCommons.sol";
import "./MockStrategyWithTransfers.sol";
import "../../contracts/vault/StanleyDsrDai.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./MockMiltonForStanley.sol";
import "../../contracts/tokens/IvToken.sol";

contract StanleyDsrDaiTest is TestCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address internal _admin;
    address internal _milton;
    MockTestnetToken internal _dai;
    MockStrategyWithTransfers internal _strategyAave;
    MockStrategyWithTransfers internal _strategyCompound;
    MockStrategyWithTransfers internal _strategyDsr;
    StanleyDsrDai internal _stanley;
    IvToken internal _ivDai;

    function setUp() public {
        _admin = vm.rememberKey(1);
        (_dai, , ) = _getStables();
        _ivDai = new IvToken( "iDAI", "iDAI", address(_dai));
        _milton = address(new MockMiltonForStanley(address(_dai)));
        _strategyAave = new MockStrategyWithTransfers();
        _strategyAave.setAsset(address(_dai));
        _strategyCompound = new MockStrategyWithTransfers();
        _strategyCompound.setAsset(address(_dai));
        _strategyDsr = new MockStrategyWithTransfers();
        _strategyDsr.setAsset(address(_dai));

        StanleyDsrDai stanleyImpl = new StanleyDsrDai(
            address(_dai),
            _milton,
            address(_strategyAave),
            address(_strategyCompound),
            address(_strategyDsr),
            address(_ivDai)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(stanleyImpl),
            abi.encodeWithSignature("initialize()")
        );
        _stanley = StanleyDsrDai(address(proxy));
        _ivDai.setStanley(address(_stanley));
        vm.prank(_milton);
        _dai.approve(address(_stanley), type(uint256).max);
        _stanley.grandMaxAllowanceForSpender(address(_dai), address(_strategyAave));
        _stanley.grandMaxAllowanceForSpender(address(_dai), address(_strategyCompound));
        _stanley.grandMaxAllowanceForSpender(address(_dai), address(_strategyDsr));

        deal(address(_dai), _milton, 1_000_000e18);
    }

    function testShouldDepositToAave() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        (uint256 vaultBalance, uint256 depositedAmount) = _stanley.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(1_000e18, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(999_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
        assertEq(0, ivMiltonBalanceBefore);
        assertEq(1_000e18, ivMiltonBalanceAfter);
    }

    function testShouldDepositToCompoundWhenAaveIsPaused() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyAave.pause();
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        (uint256 vaultBalance, uint256 depositedAmount) = _stanley.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, ivMiltonBalanceBefore);
        assertEq(1_000e18, ivMiltonBalanceAfter);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(1_000e18, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(999_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }


    function testShouldRevertWhenAllStrategiesIsPaused() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyAave.pause();
        _strategyCompound.setApr(9e15);
        _strategyCompound.pause();
        _strategyDsr.setApr(8e15);
        _strategyDsr.pause();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);


        // when
        vm.startPrank(_milton);
        vm.expectRevert(bytes(StanleyErrors.DEPOSIT_TO_STRATEGY_FAILED));
        (uint256 vaultBalance, uint256 depositedAmount) = _stanley.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(0, vaultBalance);
        assertEq(0, depositedAmount);
        assertEq(0, ivMiltonBalanceBefore);
        assertEq(0, ivMiltonBalanceAfter);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(1_000_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldDepositToCompound() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(11e15);
        _strategyDsr.setApr(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);


        // when
        vm.startPrank(_milton);
        (uint256 vaultBalance, uint256 depositedAmount) = _stanley.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, ivMiltonBalanceBefore);
        assertEq(1_000e18, ivMiltonBalanceAfter);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(1_000e18, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(999_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldDepositToDsr() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(11e15);
        _strategyDsr.setApr(12e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);


        // when
        vm.startPrank(_milton);
        (uint256 vaultBalance, uint256 depositedAmount) = _stanley.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, ivMiltonBalanceBefore);
        assertEq(1_000e18, ivMiltonBalanceAfter);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(1_000e18, dsrBalanceAfter);
        assertEq(1_000_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(999_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldDepositFirstToAveSecondToDsr() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyDsr.setApr(11e15);
        (uint256 vaultBalance, uint256 depositedAmount) = _stanley.deposit(2_000e18);
        vm.stopPrank();

        // then

        assertEq(3_000e18, vaultBalance);
        assertEq(2_000e18, depositedAmount);
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, ivMiltonBalanceBefore);
        assertEq(3_000e18, ivMiltonBalanceAfter);
        assertEq(0, dsrBalanceBefore);
        assertEq(1_000e18, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(2_000e18, dsrBalanceAfter);
        assertEq(1_000_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(997_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldWithdrawFromAaveWhenAaveHasLowerApr() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyCompound.setApr(11e15);
        _stanley.deposit(2_000e18);
        _strategyDsr.setApr(12e15);
        _stanley.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdraw(1_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(5_000e18, vaultBalance);
        assertEq(1_000e18, withdrawnAmount);
        assertEq(6_000e18, ivMiltonBalanceBefore);
        assertEq(5_000e18, ivMiltonBalanceAfter);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(2_000e18, compoundBalanceAfter);
        assertEq(3_000e18, dsrBalanceAfter);
        assertEq(994_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(995_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldWithdrawFromCompoundWhenAaveWasPaused() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyCompound.setApr(11e15);
        _stanley.deposit(2_000e18);
        _strategyDsr.setApr(12e15);
        _stanley.deposit(3_000e18);
        vm.stopPrank();
        _strategyAave.pause();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdraw(1_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(5_000e18, vaultBalance);
        assertEq(1_000e18, withdrawnAmount);
        assertEq(6_000e18, ivMiltonBalanceBefore);
        assertEq(5_000e18, ivMiltonBalanceAfter);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(1_000e18, aaveBalanceAfter);
        assertEq(1_000e18, compoundBalanceAfter);
        assertEq(3_000e18, dsrBalanceAfter);
        assertEq(994_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(995_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldWithdrawFromAaveAndCompoundWhenDsrHasHighestApr() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyCompound.setApr(11e15);
        _stanley.deposit(2_000e18);
        _strategyDsr.setApr(12e15);
        _stanley.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdraw(2_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(4_000e18, vaultBalance);
        assertEq(2_000e18, withdrawnAmount);
        assertEq(6_000e18, ivMiltonBalanceBefore);
        assertEq(4_000e18, ivMiltonBalanceAfter);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(1_000e18, compoundBalanceAfter);
        assertEq(3_000e18, dsrBalanceAfter);
        assertEq(994_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(996_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldWithdrawFromAaveAndDsrWhenCompoundHasNoAssets() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyCompound.setApr(11e15);
        _strategyDsr.setApr(12e15);
        _stanley.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);

        // when
        vm.startPrank(_milton);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdraw(2_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceAfter = _ivDai.balanceOf(_milton);

        assertEq(2_000e18, vaultBalance);
        assertEq(2_000e18, withdrawnAmount);
        assertEq(4_000e18, ivMiltonBalanceBefore);
        assertEq(2_000e18, ivMiltonBalanceAfter);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(2_000e18, dsrBalanceAfter);
        assertEq(996_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(998_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldWithdrawAllWhenRequestMoreThenBalanceOfStanley() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyCompound.setApr(11e15);
        _stanley.deposit(2_000e18);
        _strategyDsr.setApr(12e15);
        _stanley.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));
        uint256 ivMiltonBalanceBefore = _ivDai.balanceOf(_milton);


        // when
        vm.startPrank(_milton);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdraw(7_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));

        assertEq(0, vaultBalance);
        assertEq(6_000e18, withdrawnAmount);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(994_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(1_000_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }

    function testShouldWithdrawAllWhenUseWithdrawAllMethod() external {
        // given
        _strategyAave.setApr(10e15);
        _strategyCompound.setApr(9e15);
        _strategyDsr.setApr(8e15);

        vm.startPrank(_milton);
        _stanley.deposit(1_000e18);
        _strategyCompound.setApr(11e15);
        _stanley.deposit(2_000e18);
        _strategyDsr.setApr(12e15);
        _stanley.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceBefore = _dai.balanceOf(_milton);
        uint256 stanleyBalanceBefore = _dai.balanceOf(address(_stanley));

        // when
        vm.startPrank(_milton);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _stanley.withdrawAll();
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 miltonBalanceAfter = _dai.balanceOf(_milton);
        uint256 stanleyBalanceAfter = _dai.balanceOf(address(_stanley));

        assertEq(0, vaultBalance);
        assertEq(6_000e18, withdrawnAmount);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(994_000e18, miltonBalanceBefore);
        assertEq(0, stanleyBalanceBefore);
        assertEq(1_000_000e18, miltonBalanceAfter);
        assertEq(0, stanleyBalanceAfter);
    }
}
