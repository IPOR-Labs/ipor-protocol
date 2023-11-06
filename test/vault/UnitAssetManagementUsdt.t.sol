// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../TestCommons.sol";
import "./MockStrategyWithTransfers.sol";
import "../../contracts/vault/AssetManagementUsdt.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./MockAmmTreasuryForAssetManagement.sol";

contract UnitAssetManagementUsdtTest is TestCommons {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal _ammTreasury;
    MockTestnetToken internal _usdt;
    MockStrategyWithTransfers internal _strategyAave;
    MockStrategyWithTransfers internal _strategyCompound;
    AssetManagementUsdt internal _assetManagementUsdt;

    function setUp() public {
        _admin = vm.rememberKey(1);
        (, , _usdt) = _getStables();
        _ammTreasury = address(new MockAmmTreasuryForAssetManagement(address(_usdt)));
        _strategyAave = new MockStrategyWithTransfers();
        _strategyAave.setAsset(address(_usdt));
        _strategyCompound = new MockStrategyWithTransfers();
        _strategyCompound.setAsset(address(_usdt));

        AssetManagementUsdt AssetManagementUsdtImpl = new AssetManagementUsdt(
            address(_usdt),
            _ammTreasury,
            address(_strategyAave),
            address(_strategyCompound)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(AssetManagementUsdtImpl),
            abi.encodeWithSignature("initialize()")
        );

        _assetManagementUsdt = AssetManagementUsdt(address(proxy));

        vm.prank(_ammTreasury);
        _usdt.approve(address(_assetManagementUsdt), type(uint256).max);
        _assetManagementUsdt.grantMaxAllowanceForSpender(address(_usdt), address(_strategyAave));
        _assetManagementUsdt.grantMaxAllowanceForSpender(address(_usdt), address(_strategyCompound));

        deal(address(_usdt), _ammTreasury, 1_000_000e6);
    }

    function testShouldDepositToAaveShouldNotBeErrorIPOR_508() external {
        // given
        _strategyAave.setApy(10e15);
        _strategyCompound.setApy(9e15);

        uint256 aaveBalanceBefore = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdt.balanceOf(address(_assetManagementUsdt));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdt.deposit(4228811377500045388458);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdt.balanceOf(address(_assetManagementUsdt));

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

        uint256 aaveBalanceBefore = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdt.balanceOf(address(_assetManagementUsdt));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdt.deposit(4228811377500045388458);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdt.balanceOf(address(_assetManagementUsdt));

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

        uint256 aaveBalanceBefore = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdt.balanceOf(address(_assetManagementUsdt));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdt.deposit(1065341375500000000000);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdt.balanceOf(address(_assetManagementUsdt));

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

        uint256 aaveBalanceBefore = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceBefore = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceBefore = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceBefore = _usdt.balanceOf(address(_assetManagementUsdt));

        // when
        vm.startPrank(_ammTreasury);
        (uint256 vaultBalance, uint256 depositedAmount) = _assetManagementUsdt.deposit(1065341375500000000000);
        vm.stopPrank();

        // then

        uint256 aaveBalanceAfter = _usdt.balanceOf(address(_strategyAave));
        uint256 compoundBalanceAfter = _usdt.balanceOf(address(_strategyCompound));
        uint256 ammTreasuryBalanceAfter = _usdt.balanceOf(_ammTreasury);
        uint256 assetManagementBalanceAfter = _usdt.balanceOf(address(_assetManagementUsdt));

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

    function testShouldNotSendETH() public {
        //given

        //when
        vm.expectRevert(
            abi.encodePacked(
                "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
            )
        );
        (bool status, ) = address(_assetManagementUsdt).call{value: 1e18}("");

        //then
        assertTrue(!status);
    }
}
