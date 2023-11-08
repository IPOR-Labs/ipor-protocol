// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract AmmShouldClosePositionTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
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

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldClosePositionUSDTAndWithdrawFromAssetManagement() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);

        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_160_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_admin);
        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), _admin);

        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammTreasury.depositToAssetManagementInternal(20_110e18);

        uint256 ammERC20BalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 userERC20BalanceBefore = _iporProtocol.asset.balanceOf(_userTwo);
        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.totalBalance();

        uint256[] memory pfSwapIds = new uint256[](1);
        uint256[] memory rfSwapIds = new uint256[](0);
        pfSwapIds[0] = swap1;

        // when
        vm.startPrank(_userTwo);
        vm.warp(endTimestamp);
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userTwo, pfSwapIds, rfSwapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
        vm.stopPrank();

        // then
        uint256 ammERC20BalanceAfter = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 userERC20BalanceAfter = _iporProtocol.asset.balanceOf(_userTwo);
        uint256 assetManagementBalanceAfter = _iporProtocol.assetManagement.totalBalance();

        assertEq(ammERC20BalanceBefore, 17_890e6, "ammERC20BalanceBefore");
        assertEq(userERC20BalanceBefore, 9_990_000e6, "userERC20BalanceBefore");
        assertEq(assetManagementBalanceBefore, 20_110e18, "assetManagementBalanceBefore");
        assertEq(ammERC20BalanceAfter, 15509192767, "ammERC20BalanceAfter");
        assertEq(userERC20BalanceAfter, 10009803276237, "userERC20BalanceAfter");
        assertEq(assetManagementBalanceAfter, 2735739900090834400000, "assetManagementBalanceAfter");
    }

    function testShouldClosePositionUSDTAndRebalanceLiquiditationDepositEdgeCase() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            TestConstants.PERCENTAGE_10_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_160_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_admin);
        _iporProtocol.ammGovernanceService.addAppointedToRebalanceInAmm(address(_iporProtocol.asset), _admin);

        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammTreasury.depositToAssetManagementInternal(20_110e18);

        /// @dev Step required to make sure that AmmTreasury balance is higher than (Transfer Amount - Liquiditation Deposit)
        vm.prank(_liquidityProvider);
        _iporProtocol.asset.transfer(address(_iporProtocol.ammTreasury), 1910e6);

        uint256 ammERC20BalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 userERC20BalanceBefore = _iporProtocol.asset.balanceOf(_userTwo);
        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.totalBalance();

        uint256[] memory pfSwapIds = new uint256[](1);
        uint256[] memory rfSwapIds = new uint256[](0);
        pfSwapIds[0] = swap1;

        // when
        vm.warp(endTimestamp);
        vm.startPrank(_userTwo);
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userThree, pfSwapIds, rfSwapIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
        vm.stopPrank();

        // then
        uint256 ammERC20BalanceAfter = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 userERC20BalanceAfter = _iporProtocol.asset.balanceOf(_userTwo);
        uint256 assetManagementBalanceAfter = _iporProtocol.assetManagement.totalBalance();

        assertEq(ammERC20BalanceBefore, 19800e6, "ammERC20BalanceBefore");
        assertEq(userERC20BalanceBefore, 9_990_000e6, "userERC20BalanceBefore");
        assertEq(assetManagementBalanceBefore, 20_110e18, "assetManagementBalanceBefore");
        assertEq(ammERC20BalanceAfter, 17132692767, "ammERC20BalanceAfter");
        assertEq(userERC20BalanceAfter, 10009778276237, "userERC20BalanceAfter");
        assertEq(assetManagementBalanceAfter, 3022239900090834400000, "assetManagementBalanceAfter");
    }

    function testShouldClosePositionUsdtAndRebalanceWhen100PercentageLossBeneficiaryDiffThanBuyer() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        vm.prank(_userOne);
        /// @dev force 100% loss for Buyer
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_160_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(address(_iporProtocol.router));
        /// @dev transfer all AmmTreausry balance to Asset Management
        _iporProtocol.ammTreasury.depositToAssetManagementInternal(38_000 * 1e18);

        uint256 ammERC20BalanceBefore = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 userERC20BalanceBefore = _iporProtocol.asset.balanceOf(_userTwo);
        uint256 assetManagementBalanceBefore = _iporProtocol.assetManagement.totalBalance();

        uint256[] memory pfSwapIds = new uint256[](0);
        uint256[] memory rfSwapIds = new uint256[](1);
        rfSwapIds[0] = swap1;

        // when
        vm.warp(endTimestamp);
        vm.startPrank(_userTwo);
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userThree, pfSwapIds, rfSwapIds,getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
        vm.stopPrank();

        // then
        uint256 ammERC20BalanceAfter = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 userERC20BalanceAfter = _iporProtocol.asset.balanceOf(_userTwo);
        uint256 assetManagementBalanceAfter = _iporProtocol.assetManagement.totalBalance();

        assertEq(ammERC20BalanceBefore, 0, "ammERC20BalanceBefore");
        assertEq(userERC20BalanceBefore, 9_990_000e6, "userERC20BalanceBefore");
        assertEq(assetManagementBalanceBefore, 38_000 * 1e18, "assetManagementBalanceBefore");
        assertEq(ammERC20BalanceAfter, 32357181507, "ammERC20BalanceAfter");
        assertEq(userERC20BalanceAfter, 9990000000000, "userERC20BalanceAfter");
        assertEq(assetManagementBalanceAfter, 5708914383375520000000, "assetManagementBalanceAfter");
    }
}
