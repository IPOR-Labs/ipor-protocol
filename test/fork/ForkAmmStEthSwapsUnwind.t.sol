// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmStEthSwapsUnwindTest is TestForkCommons {
    event SwapUnwind(
        address asset,
        uint256 indexed swapId,
        int256 swapPnlValueToDate,
        int256 swapUnwindAmount,
        uint256 unwindFeeLPAmount,
        uint256 unwindFeeTreasuryAmount
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -487620645187861,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventStEth28daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            stETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -487620645187861,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWEth28daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -487620645187861,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventwstEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -487620645187861,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1951231740240361,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventStEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            stETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1951231740240361,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            wETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1951231740240361,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventwstEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1951231740240361,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventEth90daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1950430846962798,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventStEth90daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            stETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1950430846962798,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWEth90daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            wETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1950430846962798,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventwstEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: -1950430846962798,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventEth28daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 90064464888234,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventStEth28daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            stETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 90064464888234,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWEth28daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            wETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 90064464888234,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventwstEth28dayReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 90064464888234,
            swapUnwindAmount: -715786983025659,
            unwindFeeLPAmount: 16452593526,
            unwindFeeTreasuryAmount: 5484197842
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360154758614512,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventStEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            stETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360154758614512,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            wETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360154758614512,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventwstEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360154758614512,
            swapUnwindAmount: -795022132931308,
            unwindFeeLPAmount: 18272652614,
            unwindFeeTreasuryAmount: 6090884205
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventEth90daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360006936670183,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventStEth90daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            stETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360006936670183,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventWEth90daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wETH,
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360006936670183,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldUnwindWithCorrectEventwstEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = IwstEth(wstETH).getWstETHByStETH(1 * 1e17);

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
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
            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
            swapId: 1,
            swapPnlValueToDate: 360006936670183,
            swapUnwindAmount: -1988675434140222,
            unwindFeeLPAmount: 45662881379,
            unwindFeeTreasuryAmount: 15220960460
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }
}
