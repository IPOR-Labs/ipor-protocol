// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ArbitrumTestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import {IStETH} from "../../contracts/amm-eth/interfaces/IStETH.sol";

contract ArbitrumForkAmmSwapsLensTest is ArbitrumTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
    }

    function testShouldReturnOfferedRateWstEth() public {
        //given
        _init();

        //when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = IAmmSwapsLens(iporProtocolRouterProxy)
            .getOfferedRate(
                wstETH,
                IporTypes.SwapTenor.DAYS_90,
                1000 * 1e18,
                getRiskIndicatorsInputsWithTenor(wstETH, 0, IporTypes.SwapTenor.DAYS_90, 900),
                getRiskIndicatorsInputsWithTenor(wstETH, 1, IporTypes.SwapTenor.DAYS_90, 900)
            );

        //then
        assertGt(offeredRatePayFixed, 0, "offeredRatePayFixed");
        assertEq(offeredRateReceiveFixed, 0, "offeredRateReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapWstEthCase1() public {
        //given
        _init();

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(wstETH);

        //then
        assertEq(balances.totalCollateralPayFixed, 0, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 0, "totalCollateralReceiveFixed");
        assertEq(balances.liquidityPool, 1608191730290969156689, "liquidityPoolBalance");
        assertEq(balances.totalNotionalPayFixed, 0, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 0, "totalNotionalReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapWstEthCase2() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

        uint256 ammTreasuryErc20Balance = IStETH(wstETH).balanceOf(ammTreasuryWstEthProxy);

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

        IporTypes.AmmBalancesForOpenSwapMemory memory balancesBefore = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(wstETH);

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balancesAfter = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(wstETH);

        //then
        assertEq(balancesAfter.totalCollateralPayFixed, 9985170071753300108, "totalCollateralPayFixed");
        assertEq(balancesAfter.totalCollateralReceiveFixed, 0, "totalCollateralReceiveFixed");
        assertEq(balancesAfter.liquidityPool, 1608193645255092506635, "liquidityPoolBalance");
        assertEq(balancesAfter.totalNotionalPayFixed, 99851700717533001080, "totalNotionalPayFixed");
        assertEq(balancesAfter.totalNotionalReceiveFixed, 0, "totalNotionalReceiveFixed");
    }

    function testShouldReturnPnlPayFixedWstEthCase1() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

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

        vm.warp(block.timestamp + 10 days);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlPayFixed(wstETH, swapId);

        //then
        assertEq(pnlValue, -54763880519879408, "pnlValue");
    }

    function testShouldReturnPnlPayFixedWstEthCase2() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

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

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlPayFixed(wstETH, swapId);

        //then
        assertEq(pnlValue, 0, "pnlValue");
    }

    function testShouldReturnPnlReceiveFixedWstEthCase1() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

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

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        vm.warp(block.timestamp + 10 days);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlReceiveFixed(wstETH, swapId);

        //then
        assertEq(pnlValue, 10073175314593404, "pnlValue");
    }

    function testShouldReturnPnlReceiveFixedWstEthCase2() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

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

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlReceiveFixed(wstETH, swapId);

        //then
        assertEq(pnlValue, 0, "pnlValue");
    }

    function testShouldReturnSoapWstEth() public {
        //given
        _init();

        //when
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = IAmmSwapsLens(iporProtocolRouterProxy).getSoap(
            wstETH
        );

        //then
        assertEq(soapPayFixed, 0, "soapPayFixed");
        assertEq(soapReceiveFixed, 0, "soapReceiveFixed");
        assertEq(soap, 0, "soap");
    }

    function getRiskIndicatorsInputsWithTenor(
        address asset,
        uint direction,
        IporTypes.SwapTenor tenor,
        uint demandSpreadFactor
    ) internal view returns (AmmTypes.RiskIndicatorsInputs memory) {
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: direction == 0 ? int256(1000000000000000) : int256(-1000000000000000),
            fixedRateCapPerLeg: direction == 0 ? 20000000000000000 : 35000000000000000,
            demandSpreadFactor: demandSpreadFactor,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(asset),
            uint256(tenor),
            direction,
            messageSignerPrivateKey
        );
        return riskIndicatorsInputs;
    }
}
