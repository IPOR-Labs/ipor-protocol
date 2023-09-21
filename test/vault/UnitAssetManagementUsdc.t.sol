// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../TestCommons.sol";
import "./MockStrategyWithTransfers.sol";
import "../../contracts/vault/AssetManagementUsdc.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./MockAmmTreasuryForAssetManagement.sol";

contract UnitAssetManagementUsdcTest is TestCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _ammTreasury;
    MockTestnetToken internal _usdc;
    MockStrategyWithTransfers internal _strategyAave;
    MockStrategyWithTransfers internal _strategyCompound;
    AssetManagementUsdc internal _assetManagementUsdc;

    function setUp() public {
        _admin = vm.rememberKey(1);
        (, _usdc, ) = _getStables();
        _ammTreasury = address(new MockAmmTreasuryForAssetManagement(address(_usdc)));
        _strategyAave = new MockStrategyWithTransfers();
        _strategyAave.setAsset(address(_usdc));
        _strategyCompound = new MockStrategyWithTransfers();
        _strategyCompound.setAsset(address(_usdc));

        AssetManagementUsdc assetManagementUsdcImpl = new AssetManagementUsdc(
            address(_usdc),
            _ammTreasury,
            address(_strategyAave),
            address(_strategyCompound)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(assetManagementUsdcImpl),
            abi.encodeWithSignature("initialize()")
        );

        _assetManagementUsdc = AssetManagementUsdc(address(proxy));

        vm.prank(_ammTreasury);
        _usdc.approve(address(_assetManagementUsdc), type(uint256).max);
        _assetManagementUsdc.grantMaxAllowanceForSpender(address(_usdc), address(_strategyAave));
        _assetManagementUsdc.grantMaxAllowanceForSpender(address(_usdc), address(_strategyCompound));

        deal(address(_usdc), _ammTreasury, 1_000_000e6);
    }

    function testShouldDepositToAaveShouldNotBeErrorIPOR_508() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);

        uint256 aaveBalanceBefore = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdc.balanceOf(address(_assetManagementUsdc));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdc.deposit(4228811377500045388458);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdc.balanceOf(address(_assetManagementUsdc));

        assertEq(4228811378000000000000, vaultBalance, "vaultBalance");
        assertEq(4228811378000000000000, depositedAmount, "depositedAmount");
        assertEq(0, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(0, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(4228811378, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(0, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(1_000_000e6, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(995771188622, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldDepositToCompoundWhenAaveIsPausedShouldNotBeErrorIPOR_508() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyAave.pause();
        _strategyCompound.setApy(9e15);

        uint256 aaveBalanceBefore = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdc.balanceOf(address(_assetManagementUsdc));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdc.deposit(4228811377500045388458);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdc.balanceOf(address(_assetManagementUsdc));

        assertEq(4228811378000000000000, vaultBalance, "vaultBalance");
        assertEq(4228811378000000000000, depositedAmount, "depositedAmount");
        assertEq(0, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(0, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(0, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(4228811378, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(1_000_000e6, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(995771188622, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldDepositToAaveShouldNotBeErrorIPOR_508Case2() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);

        uint256 aaveBalanceBefore = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdc.balanceOf(address(_assetManagementUsdc));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdc.deposit(1065341375500000000000);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdc.balanceOf(address(_assetManagementUsdc));

        assertEq(1065341376000000000000, vaultBalance, "vaultBalance");
        assertEq(1065341376000000000000, depositedAmount, "depositedAmount");
        assertEq(0, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(0, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(1065341376, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(0, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(1_000_000e6, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(998934658624, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }

    function testShouldDepositToCompoundWhenAaveIsPausedShouldNotBeErrorIPOR_508Case2() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyAave.pause();
        _strategyCompound.setApy(9e15);

        uint256 aaveBalanceBefore = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdc.balanceOf(address(_assetManagementUsdc));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdc.deposit(1065341375500000000000);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdc.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdc.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdc.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdc.balanceOf(address(_assetManagementUsdc));

        assertEq(1065341376000000000000, vaultBalance, "vaultBalance");
        assertEq(1065341376000000000000, depositedAmount, "depositedAmount");
        assertEq(0, aaveBalanceBefore, "aaveBalanceBefore");
        assertEq(0, compoundBalanceBefore, "compoundBalanceBefore");
        assertEq(0, aaveBalanceAfter, "aaveBalanceAfter");
        assertEq(1065341376, compoundBalanceAfter, "compoundBalanceAfter");
        assertEq(1000000000000, ammTreasuryBalanceBefore, "ammTreasuryBalanceBefore");
        assertEq(0, assetManagementBalanceBefore, "assetManagementBalanceBefore");
        assertEq(998934658624, ammTreasuryBalanceAfter, "ammTreasuryBalanceAfter");
        assertEq(0, assetManagementBalanceAfter, "assetManagementBalanceAfter");
    }
}
