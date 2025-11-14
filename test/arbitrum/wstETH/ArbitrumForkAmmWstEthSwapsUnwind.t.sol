// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ArbitrumTestForkCommons.sol";
import "../../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../contracts/interfaces/types/AmmTypes.sol";

contract ArbitrumForkAmmWstEthSwapsUnwindTest is ArbitrumTestForkCommons {
    event SwapUnwind(
        address asset,
        uint256 indexed swapId,
        int256 swapPnlValueToDate,
        int256 swapUnwindAmount,
        uint256 unwindFeeLPAmount,
        uint256 unwindFeeTreasuryAmount
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
    }

    function testShouldGetClosingSwapDetailsPayFixedWstEthWithUnwindPnlValueNotHigherThanCollateral() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 10 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            1000e18,
            riskIndicatorsInputs
        );

        IporOracle(iporOracleProxy).addUpdater(owner);

        vm.prank(owner);
        IIporOracle(iporOracleProxy).updateIndexes(getIndexToUpdate(wstETH, 10 * 1e16));

        /// @dev move time but still unwind required for buyer
        vm.warp(block.timestamp + 20 hours);

        AmmTypesBaseV1.Swap memory swap = IAmmStorageBaseV1(ammStorageWstEthProxy).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        AmmTypes.CloseSwapRiskIndicatorsInput
            memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicatorsHighFixedRateCaps(
                IporTypes.SwapTenor.DAYS_28
            );

        uint256 closeTimestamp = block.timestamp;

        //when
        AmmTypes.ClosingSwapDetails memory closingSwapDetails = IAmmCloseSwapLens(iporProtocolRouterProxy)
            .getClosingSwapDetails(
                wstETH,
                user,
                AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
                swapId,
                closeTimestamp,
                closeRiskIndicatorsInputs
            );

        //then
        /// @dev Invariant - pnlValue never higher than collateral
        assertLe(closingSwapDetails.pnlValue, int256(swap.collateral));
    }

    function testShouldUnwindWithCorrectEventEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 10 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(wstETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 10 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: -487620645187861,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWstEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 10 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(wstETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 10 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: -487620645187861,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWstEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 40 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: -1951231740240361,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWstEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 40 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: -1950430846962798,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWstEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 10 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 10 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: 90064464888234,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWstEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 40 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: 360154758614512,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWstEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 40 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind({
            asset: wstETH,
            swapId: 1,
            swapPnlValueToDate: 360006936670183,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldCloseSwapTenor60DaysUnwindAfter60Days() public {
        //given
        _init();
        _createAmmCloseSwapServiceStEthUnwindCase1();
        _updateIporRouterImplementation();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        IIporOracle(iporOracleProxy).addUpdater(owner);

        vm.prank(owner);
        IIporOracle(iporOracleProxy).updateIndexes(getIndexToUpdate(wstETH, 5 * 1e16));

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            1000e18,
            riskIndicatorsInputs
        );

        vm.prank(owner);
        IIporOracle(iporOracleProxy).updateIndexes(getIndexToUpdate(wstETH, 1 * 1e16));

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 50 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldCloseSwapTenor60DaysUnwindAfter60DaysCloseAfterMaturityMinusOne() public {
        //given
        _init();
        _createAmmCloseSwapServiceStEthUnwindCase1();
        _updateIporRouterImplementation();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            1000e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 60 days - 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldCloseSwapTenor60DaysUnwindAfter60DaysCloseAfterMaturityPlusOne() public {
        //given
        _init();
        _createAmmCloseSwapServiceStEthUnwindCase1();
        _updateIporRouterImplementation();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            1000e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 60 days + 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldCloseSwapTenor90DaysUnwindAfter90Days() public {
        //given
        _init();
        _createAmmCloseSwapServiceStEthUnwindCase1();
        _updateIporRouterImplementation();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 40 days + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        IIporOracle(iporOracleProxy).addUpdater(owner);

        vm.prank(owner);
        IIporOracle(iporOracleProxy).updateIndexes(getIndexToUpdate(wstETH, 5 * 1e16));

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            1000e18,
            riskIndicatorsInputs
        );

        vm.prank(owner);
        IIporOracle(iporOracleProxy).updateIndexes(getIndexToUpdate(wstETH, 1 * 1e16));

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        vm.warp(block.timestamp + 50 days);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }
}
