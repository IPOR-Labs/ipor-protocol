// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/console2.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";

contract MiltonUnwindSwap is TestCommons, DataUtils, SwapUtils {
    address internal _buyer;

    IporProtocol private _iporProtocol;

    MockTestnetToken asset;
    ItfMilton milton;
    MockSpreadModel miltonSpreadModel;

    int256 unwindFlatFee = 5*1e18;

    event VirtualHedgingPosition(uint256 indexed swapId, int256 hedgingPosition);

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
    }

    function testShouldCalculatePnLForUnwindPayFixedSimple() public {
        //given
        _iporProtocol = setupIporProtocolForDai();
        asset = _iporProtocol.asset;
        milton = _iporProtocol.milton;
        miltonSpreadModel = _iporProtocol.miltonSpreadModel;

        int256 basePayoff = 900 * 1e18;
        uint256 closingTimestamp = block.timestamp + 25 days;

        IporTypes.IporSwapMemory memory swap;

        swap.id = 1;
        swap.buyer = _buyer;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = block.timestamp + 28 days;
        swap.collateral = 1000 * 1e18;
        swap.notional = 1000 * 1e18 * 100;
        swap.fixedInterestRate = 3 * 1e16;
        swap.state = 1;

        int256 expectedHedgingPosition = 878561643835616438357;
        int256 expectedBasePayoff = 900 * 1e18;
        int256 expectedPayoff = expectedBasePayoff + expectedHedgingPosition ;
        uint256 expectedIncomeFeeValue = 90 * 1e18;

        /// @dev required for spread but in this test we are using mocked spread model
        IporTypes.AccruedIpor memory fakedAccruedIpor;
        IporTypes.MiltonBalancesMemory memory fakedBalance;

        miltonSpreadModel.setCalculateQuoteReceiveFixed(1 * 1e16);

        //when
        vm.expectEmit(true, true, true, true);
        emit VirtualHedgingPosition(swap.id, expectedHedgingPosition);

        vm.prank(_buyer);
        (int256 actualPayoff, uint256 actualIncomeFeeValue) = milton.itfCalculatePayoff(
            swap,
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            basePayoff,
            fakedAccruedIpor,
            fakedBalance
        );

        //then
        assertEq(actualPayoff, expectedPayoff, "Incorrect payoff");
        assertEq(actualIncomeFeeValue, expectedIncomeFeeValue, "Incorrect income fee value");
    }

    function testShouldCalculatePnLForUnwindPayFixedExcel() public {
        //given
        _iporProtocol = setupIporProtocolForDai();
        asset = _iporProtocol.asset;
        milton = _iporProtocol.milton;
        miltonSpreadModel = _iporProtocol.miltonSpreadModel;

        int256 basePayoff = -180821917808219000000;
        uint256 closingTimestamp = block.timestamp + 11 days;

        IporTypes.IporSwapMemory memory swap;

        swap.id = 1;
        swap.buyer = _buyer;
        swap.openTimestamp = block.timestamp;
        swap.endTimestamp = block.timestamp + 28 days;
        swap.collateral = 1000 * 1e18;
        swap.notional = 1000 * 1e18 * 1000;
        swap.fixedInterestRate = 42 * 1e15;
        swap.state = 1;

        int256 expectedHedgingPosition = -749383561643835438355;
        int256 expectedBasePayoff = -180821917808219000000;
        int256 expectedPayoff = expectedBasePayoff + expectedHedgingPosition;
        uint256 expectedIncomeFeeValue = 18082191780821900000;

        /// @dev required for spread but in this test we are using mocked spread model
        IporTypes.AccruedIpor memory fakedAccruedIpor;
        IporTypes.MiltonBalancesMemory memory fakedBalance;

        miltonSpreadModel.setCalculateQuoteReceiveFixed(299 * 1e14);

        //when
        vm.expectEmit(true, true, true, true);
        emit VirtualHedgingPosition(swap.id, expectedHedgingPosition);

        vm.prank(_buyer);
        (int256 actualPayoff, uint256 actualIncomeFeeValue) = milton.itfCalculatePayoff(
            swap,
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            basePayoff,
            fakedAccruedIpor,
            fakedBalance
        );

        //then
        assertEq(actualPayoff, expectedPayoff, "Incorrect payoff");
        assertEq(actualIncomeFeeValue, expectedIncomeFeeValue, "Incorrect income fee value");
    }

    function testShouldCloseAndUnwindPayFixedSwapAsBuyerInMoreThanLast24hours() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 10 * 10**16;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapPayFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapPayFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 108663366, "Incorrect buyer balance");

    }

    function testShouldCloseAndUnwindReceiveFixedSwapAsBuyerInMoreThanLast24hours() public {
        //given
        _iporProtocol = setupIporProtocolForUsdt();
        MockTestnetToken asset = _iporProtocol.asset;
        ItfMilton milton = _iporProtocol.milton;
        ItfJoseph joseph = _iporProtocol.joseph;

        uint256 liquidityAmount = 1_000_000 * 1e6;
        uint256 totalAmount = 10_000 * 1e6;
        uint256 acceptableFixedInterestRate = 0;
        uint256 leverage = 100 * 10**18;

        asset.approve(address(joseph), liquidityAmount);
        joseph.provideLiquidity(liquidityAmount);

        asset.transfer(_buyer, totalAmount);

        vm.prank(_buyer);
        asset.approve(address(milton), totalAmount);

        uint256 buyerBalanceBefore = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceBefore = _iporProtocol.asset.balanceOf(_admin);

        vm.prank(_buyer);
        milton.openSwapReceiveFixed(totalAmount, acceptableFixedInterestRate, leverage);

        vm.warp(100 + 28 days - 24 hours - 1 seconds);

        //when
        vm.prank(_buyer);
        milton.closeSwapReceiveFixed(1);

        //then
        uint256 buyerBalanceAfter = _iporProtocol.asset.balanceOf(_buyer);
        uint256 adminBalanceAfter = _iporProtocol.asset.balanceOf(_admin);

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 108663366);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }
}
