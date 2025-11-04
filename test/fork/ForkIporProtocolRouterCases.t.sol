// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../contracts/IporClient.sol";
import {IporProtocolRouterEthereum} from "../../contracts/chains/ethereum/router/IporProtocolRouterEthereum.sol";
import {AmmPoolsLensBaseV1} from "../../contracts/base/amm/services/AmmPoolsLensBaseV1.sol";

contract ForkIporProtocolRouterCases is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_PROVIDER_URL"), 18562032);
    }

    function testShouldNotFailWhenClientIntegrateWithIporProtocolAndReturnBackEthWhenOpenSwap() public {
        // given
        _init();

        address user = _getUserAddress(1);

        IporClient iporClient = new IporClient(iporProtocolRouterProxy);

        deal(user, 1e18);

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

        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

        //when
        vm.prank(user);
        uint256 swapId = iporClient.openIporSwapPayFixed28DaysEth{value: user.balance}(riskIndicatorsInputs);

        //then
        assertEq(swapId, 1);
    }

    function testShouldReturnBalanceForOpenSwapUsdcWhenRouterHasEth() public {
        //given
        _init();

        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

        //when
        IporTypes.AmmBalancesForOpenSwapMemory memory balances = IAmmSwapsLens(iporProtocolRouterProxy)
            .getBalancesForOpenSwap(USDC);

        //then
        assertEq(balances.totalCollateralPayFixed, 17825873015180730640170, "totalCollateralPayFixed");
        assertEq(balances.totalCollateralReceiveFixed, 11446145165352924187665, "totalCollateralReceiveFixed");
        assertEq(balances.totalNotionalPayFixed, 6107616493193503532894565, "totalNotionalPayFixed");
        assertEq(balances.totalNotionalReceiveFixed, 5438565550120171901150066, "totalNotionalReceiveFixed");
        assertEq(balances.liquidityPool, 3706455723667577290180611, "liquidityPoolBalance");
    }

    function testShouldOpenPositionStEthForEth28daysPayFixedWhenRouterHasEth() public {
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

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        //send eth to router:
        vm.prank(user);
        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
            value: totalAmount
        }(user, ETH, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        //then
        uint256 ammTreasuryStEthErc20BalanceAfter = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115257294091, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
        assertEq(
            totalAmount,
            ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore + 1,
            "ammTreasuryStEthErc20BalanceAfter - ammTreasuryStEthErc20BalanceBefore"
        );
    }

    function testShouldOpenPositionStEthForStEth28daysPayFixedWhenRouterHasEth() public {
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

        uint256 ammTreasuryStEthErc20BalanceBefore = ERC20(stETH).balanceOf(ammTreasuryProxyStEth);

        uint256 userEthBalanceBefore = user.balance;

        //send eth to router:
        vm.prank(user);
        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

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
        uint256 userEthBalanceAfter = user.balance;

        AmmTypesBaseV1.Swap memory swap = AmmStorageBaseV1(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );
        /// @dev checking swap via Router
        assertEq(swapId, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(1, uint256(swap.state), "swap.state");

        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(88965876102316920, swap.collateral, "swap.collateral");
        assertEq(889658761023169200, swap.notional, "swap.notional");
        assertEq(889658761023169200, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000115257294091, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.wadLiquidationDepositAmount, "swap.wadLiquidationDepositAmount");

        assertEq(userEthBalanceBefore, userEthBalanceAfter, "user balance of Eth should be the same");
    }

    function testShouldOpenSwapTenor28DaiPayFixedRouterHasEth() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        //send eth to router:
        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            user,
            2_000 * 1e18,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(331, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(1964246590348907269306, swap.collateral, "swap.collateral");
        assertEq(19642465903489072693060, swap.notional, "swap.notional");
        assertEq(18991453998068319976528, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(52482385772994677, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldOpenSwapTenor28DaiPayFixedRouterHasEthProvideLiquidityTakeIt() public {
        //given
        _init();
        address user = _getUserAddress(22);

        deal(user, 1_000_000e18);
        deal(DAI, user, 500_000e18);

        vm.startPrank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        IStETH(stETH).submit{value: 10e18}(address(0));
        IStETH(stETH).approve(iporProtocolRouterProxy, type(uint256).max);
        vm.stopPrank();

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        //send eth to router:
        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

        vm.prank(user);
        IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityStEth(user, 1e18);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            user,
            2_000 * 1e18,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(DAI, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(331, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(1964246590348907269306, swap.collateral, "swap.collateral");
        assertEq(19642465903489072693060, swap.notional, "swap.notional");
        assertEq(18991453998068319976528, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(52482385772994677, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldProvideLiquidityWhenBatchExecutorIsUsedAndAdditionalETHIsOnRouter() external {
        // given
        _init();
        address user = _getUserAddress(22);

        deal(user, 1_000_000e18);
        deal(DAI, user, 500_000e18);

        vm.startPrank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);
        IStETH(stETH).submit{value: 50_000e18}(address(0));
        IStETH(stETH).approve(iporProtocolRouterProxy, type(uint256).max);

        IWETH9(wETH).deposit{value: 50_000e18}();
        IWETH9(wETH).approve(iporProtocolRouterProxy, type(uint256).max);
        vm.stopPrank();

        uint userEthBalanceBefore = user.balance;
        uint userIpstEthBalanceBefore = IERC20(ipstETH).balanceOf(user);
        uint userStEthBalanceBefore = IStETH(stETH).balanceOf(user);
        uint userWEthBalanceBefore = IERC20(wETH).balanceOf(user);

        uint exchangeRateBefore = AmmPoolsLensBaseV1(iporProtocolRouterProxy).getIpTokenExchangeRate(stETH);
        uint ammTreasuryStEthBalanceBefore = IStETH(stETH).balanceOf(ammTreasuryProxyStEth);

        bytes[] memory requestData = new bytes[](3);
        requestData[0] = abi.encodeWithSelector(
            IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityStEth.selector,
            user,
            100e18
        );
        requestData[1] = abi.encodeWithSelector(
            IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityWEth.selector,
            user,
            100e18
        );

        requestData[2] = abi.encodeWithSelector(
            IAmmPoolsServiceStEth(iporProtocolRouterProxy).provideLiquidityEth.selector,
            user,
            100e18
        );

        /// @dev send eth to router: 12345
        (bool success, ) = iporProtocolRouterProxy.call{value: 12345}("");

        // when
        vm.prank(user);
        IporProtocolRouterEthereum(iporProtocolRouterProxy).batchExecutor{value: 150e18}(requestData);

        // then
        uint userIpstEthBalanceAfter = IERC20(ipstETH).balanceOf(user);
        uint userStEthBalanceAfter = IStETH(stETH).balanceOf(user);
        uint userWethBalanceAfter = IERC20(wETH).balanceOf(user);

        uint exchangeRateAfter = AmmPoolsLensBaseV1(iporProtocolRouterProxy).getIpTokenExchangeRate(stETH);
        uint ammTreasuryStEthBalanceAfter = IStETH(stETH).balanceOf(ammTreasuryProxyStEth);

        assertEq(user.balance, userEthBalanceBefore - 100e18 + 12345, " user balance with additional eth 12345");
        assertEq(userIpstEthBalanceBefore, 0, " balance of userOne should be 0");
        assertEq(userStEthBalanceBefore, 49999999999999999999999, "userStEthBalanceBefore");
        assertEq(userWEthBalanceBefore, 50_000e18, " balance of userOne should be 50_000e18");
        assertEq(exchangeRateBefore, exchangeRateAfter, " exchange rate should not be changed");
        assertEq(ammTreasuryStEthBalanceBefore, 1608191730290969156689, "ammTreasuryStEthBalanceBefore");
        assertEq(userIpstEthBalanceAfter, 298822642124328954114, " userIpstEthBalanceAfter");
        assertEq(userStEthBalanceAfter, 49899999999999999999999, "userStEthBalanceAfter");
        assertEq(userWethBalanceAfter, 49_900_000000000000000000, "userWethBalanceAfter");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            1608191730290969156689 + 299999999999999999998,
            "ammTreasuryStEthBalanceAfter"
        );
    }

    function testShouldEmergencyCloseSwapTenor28DaiPayFixedRouterHasEth() public {
        //given
        _init();
        address user = _getUserAddress(22);

        vm.prank(user);
        ERC20(DAI).approve(iporProtocolRouterProxy, type(uint256).max);

        deal(DAI, user, 500_000e18);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(DAI),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapService(iporProtocolRouterProxy).openSwapPayFixed28daysDai(
            user,
            2_000 * 1e18,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //send eth to router:
        (bool success, ) = iporProtocolRouterProxy.call{value: 1}("");

        uint256[] memory pfSwapIds = new uint256[](1);
        uint256[] memory rfSwapIds = new uint256[](0);

        pfSwapIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        uint256 ownerEthBalanceBefore = owner.balance;

        //when
        vm.prank(owner);
        IAmmCloseSwapServiceDai(iporProtocolRouterProxy).emergencyCloseSwapsDai(
            pfSwapIds,
            rfSwapIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypes.Swap memory swap = AmmStorage(ammStorageProxyDai).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(swapId, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(1964246590348907269306, swap.collateral, "swap.collateral");
        assertEq(19642465903489072693060, swap.notional, "swap.notional");
        assertEq(18991453998068319976528, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(52482385772994677, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");

        /// @dev Notice! Onwer balance of ETH should be the same like it was before emergency close
        /// because method _returnBackRemainingEth is not called in this case.
        assertEq(owner.balance, ownerEthBalanceBefore, "owner balance ");
    }

    function testShouldEmergencyCloseSwapTenor28StEthPayFixedRouterHasEth() public {
        //given
        _init();
        address user = _getUserAddress(22);

        deal(user, 1_000_000e18);
        deal(DAI, user, 500_000e18);

        vm.startPrank(user);

        IStETH(stETH).submit{value: 1000 * 1e18}(address(0));
        IStETH(stETH).approve(iporProtocolRouterProxy, type(uint256).max);

        IWETH9(wETH).deposit{value: 1000 * 1e18}();
        IWETH9(wETH).approve(iporProtocolRouterProxy, type(uint256).max);

        IStETH(stETH).submit{value: 1000 * 1e18}(address(0));

        IWETH9(stETH).approve(wstETH, type(uint256).max);
        IwstEth(wstETH).wrap(1000 * 1e18);

        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);

        vm.stopPrank();

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
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
            wstETH,
            1 * 1e18,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //send eth to router:
        (bool success, ) = iporProtocolRouterProxy.call{value: 12345}("");

        uint256[] memory pfSwapIds = new uint256[](1);
        uint256[] memory rfSwapIds = new uint256[](0);

        pfSwapIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        uint256 ownerEthBalanceBefore = owner.balance;

        //when
        vm.prank(owner);
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).emergencyCloseSwapsStEth(
            pfSwapIds,
            rfSwapIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesBaseV1.Swap memory swap = AmmStorageBaseV1(ammStorageProxyStEth).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(swapId, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(1134882529820768575, swap.collateral, "swap.collateral");
        assertEq(11348825298207685750, swap.notional, "swap.notional");
        assertEq(11348825298207685750, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20001471222556239, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(1000000000000000, swap.wadLiquidationDepositAmount, "swap.liquidationDepositAmount");

        assertEq(0, uint256(swap.state), "swap.state");

        /// @dev Notice! Onwer balance of ETH should be the same like it was before emergency close
        /// because method _returnBackRemainingEth is not called in this case.
        assertEq(owner.balance, ownerEthBalanceBefore, "owner balance ");
    }
}
