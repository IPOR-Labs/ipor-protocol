// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmStEthExchangeRateTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityStEthForStEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityStEth(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityStEthForWEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityWEth(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenProvideLiquidityStEthForEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.prank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityEth{value: provideAmount}(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeStEthForStEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityStEth(user, provideAmount);
        uint256 ipstEthAmount = IERC20(ipstETH).balanceOf(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).redeemFromAmmPoolStEth(user, ipstEthAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeStEthForWEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityWEth(user, provideAmount);
        uint256 ipstEthAmount = IERC20(ipstETH).balanceOf(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).redeemFromAmmPoolStEth(user, ipstEthAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeStEthForEth() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityEth{value: provideAmount}(user, provideAmount);
        uint256 ipstEthAmount = IERC20(ipstETH).balanceOf(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).redeemFromAmmPoolStEth(user, ipstEthAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeIsZEROStEthForEth() public {
        // given
        _init();
        _createNewAmmPoolsServiceStEthWithZEROFee();
        _updateIporRouterImplementation();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 provideAmount = 1 ether;

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        // when
        vm.startPrank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityEth{value: provideAmount}(user, provideAmount);
        uint256 ipstEthAmount = IERC20(ipstETH).balanceOf(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).redeemFromAmmPoolStEth(user, ipstEthAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysStEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            stETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysWEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28dayswstEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            stETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60daysWEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            wETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60daysEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60dayswstEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            stETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90daysWEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            wETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90daysEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90dayswstEth() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            stETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysWEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            wETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28dayswstEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            stETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60daysWEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            wETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60daysEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap60dayswstEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            stETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90daysWEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90daysEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap90dayswstEthReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed90daysStEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenOpenBecauseOpeningFeeAndLiquidationDepositIsZeroSwap28daysStEth()
        public
    {
        //given
        _init();

        /// @dev setup opening fee to zero
        _createAmmOpenSwapServiceStEthCase2();
        _updateIporRouterImplementation();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            stETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenOpenBecauseOpeningFeeAndLiquidationDepositIsZeroSwap28daysWEth()
        public
    {
        //given
        _init();

        /// @dev setup opening fee to zero
        _createAmmOpenSwapServiceStEthCase2();
        _updateIporRouterImplementation();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenOpenBecauseOpeningFeeAndLiquidationDepositIsZeroSwap28daysEth() public {
        //given
        _init();

        /// @dev setup opening fee to zero
        _createAmmOpenSwapServiceStEthCase2();
        _updateIporRouterImplementation();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenOpenBecauseOpeningFeeAndLiquidationDepositIsZeroSwap28dayswstEth()
        public
    {
        //given
        _init();

        /// @dev setup opening fee to zero
        _createAmmOpenSwapServiceStEthCase2();
        _updateIporRouterImplementation();

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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenChangeStorageBalancePublicationFee() public {
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

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
        AmmTypesGenOne.Balance memory balance = AmmStorageGenOne(ammStorageProxyStEth).getBalance();
        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        uint256 balancePublicationFeeBefore = AmmStorageGenOne(ammStorageProxyStEth).getBalance().iporPublicationFee;

        //when
        vm.prank(treasurer);
        IAmmGovernanceService(iporProtocolRouterProxy).transferToCharlieTreasury(stETH, balancePublicationFeeBefore);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();
        uint256 balancePublicationFeeAfter = AmmStorageGenOne(ammStorageProxyStEth).getBalance().iporPublicationFee;

        assertEq(balancePublicationFeeAfter, 0, "iporPublicationFee after");
        assertGt(balancePublicationFeeBefore, 0, "iporPublicationFee before");
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenChangeStorageBalanceCharlieTreasury() public {
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

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(user);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
        AmmTypesGenOne.Balance memory balance = AmmStorageGenOne(ammStorageProxyStEth).getBalance();
        uint256 exchangeRateBefore = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();

        uint256 balanceTreasuryBefore = AmmStorageGenOne(ammStorageProxyStEth).getBalance().treasury;

        //when
        vm.prank(treasurer);
        IAmmGovernanceService(iporProtocolRouterProxy).transferToTreasury(stETH, balanceTreasuryBefore);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLensStEth(iporProtocolRouterProxy).getIpstEthExchangeRate();
        uint256 balanceTreasuryAfter = AmmStorageGenOne(ammStorageProxyStEth).getBalance().treasury;

        assertEq(balanceTreasuryAfter, 0, "iporPublicationFee after");
        assertGt(balanceTreasuryBefore, 0, "iporPublicationFee before");
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }
}
