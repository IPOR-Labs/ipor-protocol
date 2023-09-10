// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../TestCommons.sol";
import "./MockStrategyWithTransfers.sol";
import "../../contracts/vault/AssetManagementDai.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./MockAmmTreasuryForAssetManagement.sol";

contract UnitAssetManagementDaiTest is TestCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _ammTreasury;
    MockTestnetToken internal _dai;
    MockStrategyWithTransfers internal _strategyAave;
    MockStrategyWithTransfers internal _strategyCompound;
    MockStrategyWithTransfers internal _strategyDsr;
    AssetManagementDai internal _assetManagementDai;

    function setUp() public {
        _admin = vm.rememberKey(1);
        (_dai, , ) = _getStables();
        _ammTreasury = address(new MockAmmTreasuryForAssetManagement(address(_dai)));
        _strategyAave = new MockStrategyWithTransfers();
        _strategyAave.setAsset(address(_dai));
        _strategyCompound = new MockStrategyWithTransfers();
        _strategyCompound.setAsset(address(_dai));
        _strategyDsr = new MockStrategyWithTransfers();
        _strategyDsr.setAsset(address(_dai));

        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai(
            address(_dai),
            _ammTreasury,
            3,
            2,
            address(_strategyAave),
            address(_strategyCompound),
            address(_strategyDsr)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(assetManagementDaiImpl), abi.encodeWithSignature("initialize()"));

        _assetManagementDai = AssetManagementDai(address(proxy));

        vm.prank(_ammTreasury);
        _dai.approve(address(_assetManagementDai), type(uint256).max);
        _assetManagementDai.grantMaxAllowanceForSpender(address(_dai), address(_strategyAave));
        _assetManagementDai.grantMaxAllowanceForSpender(address(_dai), address(_strategyCompound));
        _assetManagementDai.grantMaxAllowanceForSpender(address(_dai), address(_strategyDsr));

        deal(address(_dai), _ammTreasury, 1_000_000e18);
    }

    function testShouldDepositToAave() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementDai.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(1_000e18, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(999_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldDepositToCompoundWhenAaveIsPaused() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyAave.pause();
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementDai.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(1_000e18, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(999_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldRevertWhenAllStrategiesIsPaused() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyAave.pause();
        _strategyCompound.setApy(9e15);
        _strategyCompound.pause();
        _strategyDsr.setApy(8e15);
        _strategyDsr.pause();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        vm.expectRevert(bytes(AssetManagementErrors.DEPOSIT_TO_STRATEGY_FAILED));
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementDai.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(0, vaultBalance);
        assertEq(0, depositedAmount);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(1_000_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldDepositToCompound() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(11e15);
        _strategyDsr.setApy(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementDai.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(1_000e18, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(1_000_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(999_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldDepositToDsr() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(11e15);
        _strategyDsr.setApy(12e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementDai.deposit(1_000e18);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(1_000e18, vaultBalance);
        assertEq(1_000e18, depositedAmount);
        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(1_000e18, dsrBalanceAfter);
        assertEq(1_000_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(999_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldDepositFirstToAveSecondToDsr() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyDsr.setApy(11e15);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementDai.deposit(2_000e18);
        vm.stopPrank();

        // then

        assertEq(3_000e18, vaultBalance);
        assertEq(2_000e18, depositedAmount);
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(0, aaveBalanceBefore);
        assertEq(0, compoundBalanceBefore);
        assertEq(0, dsrBalanceBefore);
        assertEq(1_000e18, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(2_000e18, dsrBalanceAfter);
        assertEq(1_000_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(997_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldWithdrawFromAaveWhenAaveHasLowerApr() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyCompound.setApy(11e15);
        _assetManagementDai.deposit(2_000e18);
        _strategyDsr.setApy(12e15);
        _assetManagementDai.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _assetManagementDai.withdraw(1_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(4_999e18, vaultBalance, "vaultBalance");
        assertEq(1_001e18, withdrawnAmount, "withdrawnAmount");
        assertEq(1_000e18, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(2_000e18, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(3_000e18, dsrBalanceBefore, "dsrBalanceBefore");
        assertEq(0, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(1_999e18, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(3_000e18, dsrBalanceAfter, "dsrBalanceAfter");
        assertEq(994_000e18, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(995_001e18, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldWithdrawFromCompoundWhenAaveWasPaused() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyCompound.setApy(11e15);
        _assetManagementDai.deposit(2_000e18);
        _strategyDsr.setApy(12e15);
        _assetManagementDai.deposit(3_000e18);
        vm.stopPrank();
        _strategyAave.pause();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _assetManagementDai.withdraw(1_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(4_999e18, vaultBalance, "vaultBalance");
        assertEq(1_001e18, withdrawnAmount, "withdrawnAmount");
        assertEq(1_000e18, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(2_000e18, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(3_000e18, dsrBalanceBefore, "dsrBalanceBefore");
        assertEq(1_000e18, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(999e18, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(3_000e18, dsrBalanceAfter, "dsrBalanceAfter");
        assertEq(994_000e18, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(995_001e18, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldWithdrawFromAaveAndCompoundWhenDsrHasHighestApr() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyCompound.setApy(11e15);
        _assetManagementDai.deposit(2_000e18);
        _strategyDsr.setApy(12e15);
        _assetManagementDai.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _assetManagementDai.withdraw(2_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(3_999e18, vaultBalance, "vaultBalance");
        assertEq(2_001e18, withdrawnAmount, "withdrawnAmount");
        assertEq(1_000e18, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(2_000e18, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(3_000e18, dsrBalanceBefore, "dsrBalanceBefore");
        assertEq(0, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(999e18, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(3_000e18, dsrBalanceAfter, "dsrBalanceAfter");
        assertEq(994_000e18, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(996_001e18, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldWithdrawFromAaveAndDsrWhenCompoundHasNoAssets() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyCompound.setApy(11e15);
        _strategyDsr.setApy(12e15);
        _assetManagementDai.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _assetManagementDai.withdraw(2_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(1_999e18, vaultBalance, "vaultBalance");
        assertEq(2_001e18, withdrawnAmount, "withdrawnAmount");
        assertEq(1_000e18, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(0, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(3_000e18, dsrBalanceBefore, "dsrBalanceBefore");
        assertEq(0, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(0, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(1_999e18, dsrBalanceAfter, "dsrBalanceAfter");
        assertEq(996_000e18, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(998_001e18, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldWithdrawAllWhenRequestMoreThenBalanceOfStanley() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyCompound.setApy(11e15);
        _assetManagementDai.deposit(2_000e18);
        _strategyDsr.setApy(12e15);
        _assetManagementDai.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _assetManagementDai.withdraw(7_000e18);
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(0, vaultBalance);
        assertEq(6_000e18, withdrawnAmount);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(994_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(1_000_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }

    function testShouldWithdrawAllWhenUseWithdrawAllMethod() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);
        _strategyDsr.setApy(8e15);

        vm.startPrank(_ammTreasury);
        _assetManagementDai.deposit(1_000e18);
        _strategyCompound.setApy(11e15);
        _assetManagementDai.deposit(2_000e18);
        _strategyDsr.setApy(12e15);
        _assetManagementDai.deposit(3_000e18);
        vm.stopPrank();

        uint256 aaveBalanceBefore = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceBefore = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceBefore = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _dai.balanceOf(address(_assetManagementDai));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 withdrawnAmount, uint256 vaultBalance) = _assetManagementDai.withdrawAll();
        vm.stopPrank();

        // then
        uint256 aaveBalanceAfter = _dai.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _dai.balanceOf(address(_strategyCompound));
        uint256 dsrBalanceAfter = _dai.balanceOf(address(_strategyDsr));
        uint256 ammTreasuryBalanceAfter = _dai.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _dai.balanceOf(address(_assetManagementDai));

        assertEq(0, vaultBalance);
        assertEq(6_000e18, withdrawnAmount);
        assertEq(1_000e18, aaveBalanceBefore);
        assertEq(2_000e18, compoundBalanceBefore);
        assertEq(3_000e18, dsrBalanceBefore);
        assertEq(0, aaveBalanceAfter);
        assertEq(0, compoundBalanceAfter);
        assertEq(0, dsrBalanceAfter);
        assertEq(994_000e18, ammTreasuryBalanceBefore);
        assertEq(0, assetManagementBalanceBefore);
        assertEq(1_000_000e18, ammTreasuryBalanceAfter);
        assertEq(0, assetManagementBalanceAfter);
    }
}
