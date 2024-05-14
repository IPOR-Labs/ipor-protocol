// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ArbitrumTestForkCommons.sol";
import "../../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../contracts/interfaces/types/AmmTypes.sol";

contract ArbitrumForkAmmWstEthExchangeRateTest is ArbitrumTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityWstEthForWstEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        // when
        vm.prank(user);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).provideLiquidityWstEth(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeWstEthForWstEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        // when
        vm.startPrank(user);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).provideLiquidityWstEth(user, provideAmount);
        uint256 ipwstEthAmount = IERC20(ipwstETH).balanceOf(user);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).redeemFromAmmPoolWstEth(user, ipwstEthAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeIsZEROWstEthForWstEth()
        public
    {
        // given
        _init();
        _createNewAmmPoolsServiceWstEthWithZEROFee();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        // when
        vm.startPrank(user);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).provideLiquidityWstEth(user, provideAmount);

        uint256 ipwstEthAmount = IERC20(ipwstETH).balanceOf(user);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).redeemFromAmmPoolWstEth(user, ipwstEthAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysWStEth() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60daysStEth() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90daysStEth() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysStEthReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60daysStEthReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90daysStEthReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenOpenBecauseOpeningFeeAndLiquidationDepositIsZeroSwap28daysStEth()
        public
    {
        //given
        _init();

        /// @dev setup opening fee to zero
        _createAmmOpenSwapServiceWstEthCase2();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenChangeStorageBalancePublicationFee() public {
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
            expiration: block.timestamp + 1000,
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
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 1 days + 1);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
        AmmTypesBaseV1.Balance memory balance = AmmStorageBaseV1(ammStorageWstEthProxy).getBalance();
        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        uint256 balancePublicationFeeBefore = AmmStorageBaseV1(ammStorageWstEthProxy).getBalance().iporPublicationFee;

        //when
        vm.prank(treasurer);
        IAmmGovernanceService(iporProtocolRouterProxy).transferToCharlieTreasury(wstETH, balancePublicationFeeBefore);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);
        uint256 balancePublicationFeeAfter = AmmStorageBaseV1(ammStorageWstEthProxy).getBalance().iporPublicationFee;

        assertEq(balancePublicationFeeAfter, 0, "iporPublicationFee after");
        assertGt(balancePublicationFeeBefore, 0, "iporPublicationFee before");
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenChangeStorageBalanceDAOTreasury() public {
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
            expiration: block.timestamp + 1000,
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
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 1 days + 1);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
        AmmTypesBaseV1.Balance memory balance = AmmStorageBaseV1(ammStorageWstEthProxy).getBalance();
        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        uint256 balanceTreasuryBefore = AmmStorageBaseV1(ammStorageWstEthProxy).getBalance().treasury;

        //when
        vm.prank(treasurer);
        IAmmGovernanceService(iporProtocolRouterProxy).transferToTreasury(wstETH, balanceTreasuryBefore);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);
        uint256 balanceTreasuryAfter = AmmStorageBaseV1(ammStorageWstEthProxy).getBalance().treasury;

        assertEq(balanceTreasuryAfter, 0, "iporPublicationFee after");
        assertGt(balanceTreasuryBefore, 0, "iporPublicationFee before");
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenOpeningFeeZeroAndOpenSwapInputAssetStEth() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        /// @dev setup opening fee to zero
        _createAmmOpenSwapServiceWstEthCase3();
        _setupAssetServices();

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
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(wstETH);
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }
}
