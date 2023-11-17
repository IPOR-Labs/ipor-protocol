// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmStEthCloseSwapsTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    function testShouldClosePositionStEthForStEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            stETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
        }(ETH, user, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wstETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForStEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            stETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699008031124, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
        }(ETH, user, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699008031124, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699008031124, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wstETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699008031124, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForStEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            stETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000698721097217, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
        }(ETH, user, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000698721097217, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000698721097217, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth90daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wstETH,
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000698721097217, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForStEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            stETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300685646177, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
        }(ETH, user, totalAmount, 0, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300685646177, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300685646177, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wstETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300685646177, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForStEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            stETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300991968876, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
        }(ETH, user, totalAmount, 0, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300991968876, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300991968876, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wstETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89926088146728691, swap.collateral, "swap.collateral");
        assertEq(899260881467286910, swap.notional, "swap.notional");
        assertEq(899260881467286910, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694300991968876, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForStEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            stETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694301278902783, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
        }(ETH, user, totalAmount, 0, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694301278902783, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForWEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694301278902783, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldClosePositionStEthForwstEth90daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
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
            wstETH,
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_90
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesGenOne.Swap memory swap = AmmStorageGenOne(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            swapId
        );

        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(89889177726091096, swap.collateral, "swap.collateral");
        assertEq(898891777260910960, swap.notional, "swap.notional");
        assertEq(898891777260910960, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(3694301278902783, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");
    }
}
