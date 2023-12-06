// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmSwapsLensTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    function testShouldReturnOfferedRateUsdt() public {
        //given
        _init();

        //when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = IAmmSwapsLens(iporProtocolRouterProxy)
            .getOfferedRate(
                USDT,
                IporTypes.SwapTenor.DAYS_90,
                1000 * 1e18,
                getRiskIndicatorsInputsWithTenor(USDT, 0, IporTypes.SwapTenor.DAYS_90, 900),
                getRiskIndicatorsInputsWithTenor(USDT, 1, IporTypes.SwapTenor.DAYS_90, 900)
            );

        //then
        assertGt(offeredRatePayFixed, 0, "offeredRatePayFixed");
        assertGt(offeredRateReceiveFixed, 0, "offeredRateReceiveFixed");
    }

    function testShouldReturnOfferedRateUsdc() public {
        //given
        _init();

        //when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = IAmmSwapsLens(iporProtocolRouterProxy)
            .getOfferedRate(
                USDC,
                IporTypes.SwapTenor.DAYS_90,
                1000 * 1e18,
                getRiskIndicatorsInputsWithTenor(USDC, 0, IporTypes.SwapTenor.DAYS_90, 900),
                getRiskIndicatorsInputsWithTenor(USDC, 1, IporTypes.SwapTenor.DAYS_90, 900)
            );

        //then
        assertGt(offeredRatePayFixed, 0, "offeredRatePayFixed");
        assertGt(offeredRateReceiveFixed, 0, "offeredRateReceiveFixed");
    }

    function testShouldReturnOfferedRateDai() public {
        //given
        _init();

        //when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = IAmmSwapsLens(iporProtocolRouterProxy)
            .getOfferedRate(
                DAI,
                IporTypes.SwapTenor.DAYS_90,
                1000 * 1e18,
                getRiskIndicatorsInputsWithTenor(DAI, 0, IporTypes.SwapTenor.DAYS_90, 900),
                getRiskIndicatorsInputsWithTenor(DAI, 1, IporTypes.SwapTenor.DAYS_90, 900)
            );

        //then
        assertGt(offeredRatePayFixed, 0, "offeredRatePayFixed");
        assertGt(offeredRateReceiveFixed, 0, "offeredRateReceiveFixed");
    }

    function testShouldReturnOfferedRateStEth() public {
        //given
        _init();

        //when
        (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) = IAmmSwapsLens(iporProtocolRouterProxy)
            .getOfferedRate(
                stETH,
                IporTypes.SwapTenor.DAYS_90,
                1000 * 1e18,
                getRiskIndicatorsInputsWithTenor(stETH, 0, IporTypes.SwapTenor.DAYS_90, 900),
                getRiskIndicatorsInputsWithTenor(stETH, 1, IporTypes.SwapTenor.DAYS_90, 900)
            );

        //then
        assertGt(offeredRatePayFixed, 0, "offeredRatePayFixed");
        assertEq(offeredRateReceiveFixed, 0, "offeredRateReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapUsdc() public {
        //given
        _init();

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(USDC);

        //then
        assertEq(balances.totalCollateralPayFixed, 17825873015180730640170, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 11446145165352924187665, "totalCollateralReceiveFixed");
        assertEq(balances.liquidityPool, 3705871659406544199057522, "liquidityPoolBalance");
        assertEq(balances.totalNotionalPayFixed, 6107616493193503532894565, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 5438565550120171901150066, "totalNotionalReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapUsdt() public {
        //given
        _init();

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(USDT);

        //then
        assertEq(balances.totalCollateralPayFixed, 737802071965033573688, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 99999999770736445500, "totalCollateralReceiveFixed");
        assertEq(balances.liquidityPool, 2667440921110203210028509, "liquidityPoolBalance");
        assertEq(balances.totalNotionalPayFixed, 369638838054481820417688, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 24997969548656956276528, "totalNotionalReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapDai() public {
        //given
        _init();

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(DAI);

        //then
        assertEq(balances.totalCollateralPayFixed, 1453316901408450704442, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 4713715726233326275407, "totalCollateralReceiveFixed");
        assertEq(balances.liquidityPool, 5126679256988652388452333, "liquidityPoolBalance");
        assertEq(balances.totalNotionalPayFixed, 203464366197183098621880, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 2060970330827863645871645, "totalNotionalReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapStEthCase1() public {
        //given
        _init();

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(stETH);

        //then
        assertEq(balances.totalCollateralPayFixed, 0, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 0, "totalCollateralReceiveFixed");
        assertEq(balances.liquidityPool, 1608191730290969156689, "liquidityPoolBalance");
        assertEq(balances.totalNotionalPayFixed, 0, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 0, "totalNotionalReceiveFixed");
    }

    function testShouldReturnBalanceForOpenSwapStEthCase2() public {
        //given
        _init();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 10 * 1e18;

        uint256 ammTreasuryErc20Balance = IStETH(stETH).balanceOf(ammTreasuryProxyStEth);

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
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(stETH);

        //then
        assertEq(balances.totalCollateralPayFixed, 9985170071753300108, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 0, "totalCollateralReceiveFixed");
        assertEq(balances.liquidityPool, 1608194645255092506635, "liquidityPoolBalance");
        assertEq(balances.totalNotionalPayFixed, 99851700717533001080, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 0, "totalNotionalReceiveFixed");
    }

    function testShouldReturnPnlPayFixedStEthCase1() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        vm.warp(block.timestamp + 10 days);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlPayFixed(stETH, swapId);

        //then
        assertEq(pnlValue, -54763880519879408, "pnlValue");
    }

    function testShouldReturnPnlPayFixedStEthCase2() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlPayFixed(stETH, swapId);

        //then
        assertEq(pnlValue, 0, "pnlValue");
    }

    function testShouldReturnPnlReceiveFixedStEthCase1() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

        vm.warp(block.timestamp + 10 days);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlReceiveFixed(stETH, swapId);

        //then
        assertEq(pnlValue, 10073175314593404, "pnlValue");
    }

    function testShouldReturnPnlReceiveFixedStEthCase2() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 0, 10e18, riskIndicatorsInputs);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlReceiveFixed(stETH, swapId);

        //then
        assertEq(pnlValue, 0, "pnlValue");
    }

    function testShouldReturnPnlReceiveFixedDai() public {
        //given
        _init();

        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000 * 1e18);

        uint256 totalAmount = 10000 * 1e18;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: -1000000000000000,
            fixedRateCapPerLeg: 35000000000000000,
            demandSpreadFactor: 900,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_90),
            1,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapReceiveFixed90daysDai(
            user,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        vm.warp(block.timestamp + 10 days);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlReceiveFixed(DAI, swapId);

        //then
        assertEq(pnlValue, -37675638710819723664, "pnlValue");
    }

    function testShouldReturnPnlPayFixedDai() public {
        //given
        _init();

        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000 * 1e18);

        uint256 totalAmount = 10000 * 1e18;

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: -1000000000000000,
            fixedRateCapPerLeg: 35000000000000000,
            demandSpreadFactor: 900,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_90),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed90daysDai(
            user,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        vm.warp(block.timestamp + 10 days);

        //when
        int256 pnlValue = IAmmSwapsLens(iporProtocolRouterProxy).getPnlPayFixed(DAI, swapId);

        //then
        assertEq(pnlValue, 2730384961607909412, "pnlValue");
    }

    function testShouldReturnSoapStEth() public {
        //given
        _init();

        //when
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = IAmmSwapsLens(iporProtocolRouterProxy).getSoap(
            stETH
        );

        //then
        assertEq(soapPayFixed, 0, "soapPayFixed");
        assertEq(soapReceiveFixed, 0, "soapReceiveFixed");
        assertEq(soap, 0, "soap");
    }

    function testShouldReturnSoapUsdt() public {
        //given
        _init();

        //when
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = IAmmSwapsLens(iporProtocolRouterProxy).getSoap(
            USDT
        );

        //then
        assertEq(soapPayFixed, 54822943249309451537, "soapPayFixed");
        assertEq(soapReceiveFixed, -40180107558738609182, "soapReceiveFixed");
        assertEq(soap, 14642835690570842355, "soap");
    }

    function testShouldReturnSoapUsdc() public {
        //given
        _init();

        //when
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = IAmmSwapsLens(iporProtocolRouterProxy).getSoap(
            USDC
        );

        //then
        assertEq(soapPayFixed, 8608493194571881388709, "soapPayFixed");
        assertEq(soapReceiveFixed, -4465377090671542839006, "soapReceiveFixed");
        assertEq(soap, 4143116103900338549703, "soap");
    }

    function testShouldReturnSoapDai() public {
        //given
        _init();

        //when
        (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) = IAmmSwapsLens(iporProtocolRouterProxy).getSoap(
            DAI
        );

        //then
        assertEq(soapPayFixed, 92354150919127631143, "soapPayFixed");
        assertEq(soapReceiveFixed, -1051745777561421105473, "soapReceiveFixed");
        assertEq(soap, -959391626642293474330, "soap");
    }

    function getRiskIndicatorsInputsWithTenor(
        address asset,
        uint direction,
        IporTypes.SwapTenor tenor,
        uint demandSpreadFactor
    ) internal returns (AmmTypes.RiskIndicatorsInputs memory) {
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
