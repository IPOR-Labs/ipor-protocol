// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/amm/AmmStorage.sol";

contract AmmUnwindSwap is TestCommons {
    address internal _buyer;

    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    event SwapUnwind(
        address asset,
        uint256 indexed swapId,
        int256 swapPnlValueToDate,
        int256 swapUnwindAmount,
        uint256 unwindFeeLPAmount,
        uint256 unwindFeeTreasuryAmount
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.iporOracleUpdater = _admin;
        _cfg.iporRiskManagementOracleUpdater = _admin;
    }

    function testShouldUnwindPayFixedSimple() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        int256 expectedSwapPnlValueToDate = -254653454130672346935;
        int256 expectedSwapUnwindAmount = -1171989497612087069637;
        uint256 expectedOpeningFeeLpAmount = 29145104043000041192;
        uint256 expectedOpeningFeeTreasuryAmount = 14579841942471256;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        vm.warp(5 days);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        int256 pnlValue = _iporProtocol.ammSwapsLens.getPnlPayFixed(address(_iporProtocol.asset), 1);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            address(_iporProtocol.asset),
            swap.id,
            expectedSwapPnlValueToDate,
            expectedSwapUnwindAmount,
            expectedOpeningFeeLpAmount,
            expectedOpeningFeeTreasuryAmount
        );
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);

        //then
        assertGe(pnlValue, expectedSwapUnwindAmount);
    }

    function testShouldUnwindPayFixedWhenCloseTwoPositionInDifferentMoment() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;

        int256 expectedSwapPnlValueToDateTwo = -47677244969467080928;
        int256 expectedSwapUnwindAmountTwo = -74502689729439282708;
        uint256 expectedUnwindFeeLpAmountTwo = 16473326053178158123;
        uint256 expectedUnwindFeeTreasuryAmountTwo = 8240783418298228;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, 2 * 10_000 * 1e18);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), 2 * 10_000 * 1e18);

        vm.prank(_admin);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_2_5_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.startPrank(_buyer);
        uint256 swapIdOne = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            10_000 * 1e18,
            10 * 10 ** 16,
            100 * 10 ** 18,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        vm.startPrank(_buyer);
        uint256 swapIdTwo = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            10_000 * 1e18,
            10 * 10 ** 16,
            100 * 10 ** 18,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        AmmTypes.Swap memory swapOne = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        AmmTypes.Swap memory swapTwo = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            2
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;

        vm.warp(5 days);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCostumeCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

//      when/then
        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            address(_iporProtocol.asset),
            swapOne.id,
            -13739566523224092853,
            -121691316061789903590,
            29145104043000041192,
            14579841942471256
        );
        _iporProtocol.ammCloseSwapService.closeSwapsDai(
            _buyer,
            swapPfIds,
            new uint256[](0),
            closeSwapRiskIndicatorsInput
        );

        vm.warp(15 days);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput2 = getCostumeCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            address(_iporProtocol.asset),
            swapTwo.id,
            expectedSwapPnlValueToDateTwo,
            expectedSwapUnwindAmountTwo,
            expectedUnwindFeeLpAmountTwo,
            expectedUnwindFeeTreasuryAmountTwo
        );

        swapPfIds[0] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(
            _buyer,
            swapPfIds,
            new uint256[](0),
            closeSwapRiskIndicatorsInput2
        );
    }

    function testShouldUnwindReceiveFixedWhenCloseTwoPositionInDifferentMoment() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        int256 expectedSwapPnlValueToDateTwo = -47674791525493728262;
        int256 expectedSwapUnwindAmountTwo = -74502036263550658044;
        uint256 expectedUnwindFeeLpAmountTwo = 16473326053178158123;
        uint256 expectedUnwindFeeTreasuryAmountTwo = 8240783418298228;

        _iporProtocol.asset.approve(address(_iporProtocol.router), 1_000_000 * 1e18);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, 1_000_000 * 1e18);
        _iporProtocol.asset.transfer(_buyer, 2 * 10_000 * 1e18);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), 2 * 10_000 * 1e18);

        vm.prank(_admin);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_2_5_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: -1000000000000000,
            fixedRateCapPerLeg: 35000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.startPrank(_buyer);
        uint256 swapIdOne = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            10_000 * 1e18,
            0,
            100 * 10 ** 18,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        vm.startPrank(_buyer);
        uint256 swapIdTwo = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            10_000 * 1e18,
            0,
            100 * 10 ** 18,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        AmmTypes.Swap memory swapOne = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        AmmTypes.Swap memory swapTwo = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            2
        );

        //when/then

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;

        vm.warp(5 days);
        vm.startPrank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            address(_iporProtocol.asset),
            1,
            -13739362625080234294,
            -121690676944970284581,
            29145104043000041192,
            14579841942471256
        );
        _iporProtocol.ammCloseSwapService.closeSwapsDai(
            _buyer,
            swapPfIds,
            swapRfIds,
            getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28)
        );
        vm.stopPrank();

        vm.warp(15 days);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );
        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(
            address(_iporProtocol.asset),
            swapTwo.id,
            expectedSwapPnlValueToDateTwo,
            expectedSwapUnwindAmountTwo,
            expectedUnwindFeeLpAmountTwo,
            expectedUnwindFeeTreasuryAmountTwo
        );

        swapRfIds[0] = 2;

        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
    }

    function testShouldUnwindPayFixedDaiCorrectTransfer() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;
        uint256 acceptableFixedInterestRate = 10 * 10 ** 16;
        uint256 leverage = 100 * 10 ** 18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        vm.warp(5 days);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        /// @dev value include subtracted unwind fee
        uint256 expectedAmountToTransfer = 7824222809664918933294;
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        //then
        emit Transfer(address(_iporProtocol.ammTreasury), _buyer, expectedAmountToTransfer);
        //when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
    }

    function testShouldUnwindReceiveFixedDaiCorrectTransfer() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10 ** 18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: -1000000000000000,
            fixedRateCapPerLeg: 35000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            totalAmount,
            acceptableFixedInterestRate,
            leverage,
            riskIndicatorsInputs
        );
        vm.stopPrank();

        vm.warp(5 days);

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        /// @dev value include subtracted unwind fee
        uint256 expectedAmountToTransfer = 8082874034293901023151;

        vm.prank(_buyer);
        vm.expectEmit(true, true, true, true);
        //then
        emit Transfer(address(_iporProtocol.ammTreasury), _buyer, expectedAmountToTransfer);
        //when
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral99PercentageUnwindFeePayFixedDai() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            10 * 10 ** 16,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), PAY_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral15PercentageUnwindFeePayFixedDai() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _buyer,
            totalAmount,
            10 * 10 ** 16,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), PAY_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral99PercentageUnwindFeeReceiveFixedDai() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            totalAmount,
            0,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral15PercentageUnwindFeeReceiveFixedDai() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;
        uint256 totalAmount = 10_000 * 1e18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _buyer,
            totalAmount,
            0,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral99PercentageUnwindFeePayFixedUsdt() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            10 * 10 ** 16,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), PAY_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral15PercentageUnwindFeePayFixedUsdt() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _buyer,
            totalAmount,
            10 * 10 ** 16,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), PAY_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral99PercentageUnwindFeeReceiveFixedUsdt() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            0,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function testShouldNotUnwindBecauseNotEfficientCollateral15PercentageUnwindFeeReceiveFixedUsdt() public {
        //given
        _cfg.closeSwapServiceTestCase = BuilderUtils.AmmCloseSwapServiceTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_admin, liquidityAmount);
        _iporProtocol.asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        _iporProtocol.asset.approve(address(_iporProtocol.router), totalAmount);

        vm.startPrank(_buyer);
        uint256 swapId = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _buyer,
            totalAmount,
            0,
            100 * 10 ** 18,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), RECEIVE_FIXED)
        );
        vm.stopPrank();

        vm.warp(5 days);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = 1;
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeSwapRiskIndicatorsInput = getCloseRiskIndicatorsInputs(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        vm.startPrank(_buyer);
        vm.expectRevert(abi.encodePacked(AmmErrors.COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP));
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_buyer, swapPfIds, swapRfIds, closeSwapRiskIndicatorsInput);
        vm.stopPrank();
    }

    function getCostumeCloseRiskIndicatorsInputs(address asset, IporTypes.SwapTenor tenor) internal returns (AmmTypes.CloseSwapRiskIndicatorsInput memory riskIndicatorsInputs) {
        riskIndicatorsInputs.payFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.receiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: -1000000000000000,
            fixedRateCapPerLeg: 35000000000000000,
            demandSpreadFactor: 280,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.payFixed.signature = signRiskParams(
            riskIndicatorsInputs.payFixed,
            address(asset),
            uint256(tenor),
            0,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );
        riskIndicatorsInputs.receiveFixed.signature = signRiskParams(
            riskIndicatorsInputs.receiveFixed,
            address(asset),
            uint256(tenor),
            1,
            _iporProtocolFactory.riskParamSignerPrivateKey()
        );

    }
}
