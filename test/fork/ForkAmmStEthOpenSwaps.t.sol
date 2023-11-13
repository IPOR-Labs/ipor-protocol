// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";

contract ForkAmmStEthOpenSwapsTest is TestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    function testShouldOpenPositionStEthForETH() public {
        //TODO: implement
    }

    function testShouldOpenPositionStEthForWETH() public {
        //TODO: implement
    }

    function testShouldOpenPositionStEthForStEth() public {
        //given
        _init();
        address user = 0x2bf3937b8BcccE4B65650F122Bb3f1976B937B2f;

        vm.prank(user);
        ERC20(stETH).approve(iporProtocolRouterProxy, type(uint256).max);

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

        //when
        vm.prank(user);

        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
            stETH,
            user,
            1 * 1e17,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        IAmmSwapsLens.IporSwap[] memory swaps;
        (, swaps) = IAmmSwapsLens(iporProtocolRouterProxy).getSwaps(stETH, user, 0, 10);
        IAmmSwapsLens.IporSwap memory swap = swaps[0];

        /// @dev checking swap via Router
        assertEq(1, swap.id, "swapId");
        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(block.timestamp, swap.openTimestamp, "swap.openTimestamp");
        assertEq(89965492687736186, swap.collateral, "swap.collateral");
        assertEq(899654926877361860, swap.notional, "swap.notional");
        assertEq(899654926877361860, swap.ibtQuantity, "swap.ibtQuantity");
        assertEq(20000699314353823, swap.fixedInterestRate, "swap.fixedInterestRate");
        assertEq(25000000000000000000, swap.liquidationDepositAmount, "swap.liquidationDepositAmount");
        assertEq(1, swap.state, "swap.state");
    }

    function testShouldTransferCorrectLiquidationDepositAmountAfterClose() public {}

    function testAmmSwapsLensGetSwapsLiquiditaionDepositAmountIsCorrect() public {}
}
