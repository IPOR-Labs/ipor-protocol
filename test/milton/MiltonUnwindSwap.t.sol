// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

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
import "../../contracts/mocks/stanley/MockCaseBaseStanley.sol";
import "../../contracts/mocks/milton/MockCase2Milton18D.sol";
import "../../contracts/mocks/milton/MockCase3Milton18D.sol";

contract MiltonUnwindSwap is TestCommons, DataUtils, SwapUtils {
    address internal _buyer;

    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    MockTestnetToken asset;
    ItfMilton milton;
    MockSpreadModel spreadModel;

    int256 unwindFlatFee = 5 * 1e18;

    event SwapUnwind(uint256 indexed swapId, int256 swapPayoffToDate, int256 swapUnwindValue, uint256 swapUnwindOpeningFee);

    function setUp() public {
        _admin = address(this);
        _buyer = _getUserAddress(1);
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE1;
        _cfg.iporOracleUpdater = _admin;
        _cfg.iporRiskManagementOracleUpdater = _admin;
    }

    function testShouldCalculatePnLForUnwindPayFixedSimple() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        asset = _iporProtocol.asset;
        milton = _iporProtocol.milton;
        spreadModel = _iporProtocol.spreadModel;

        int256 swapPayoffToDate = 900 * 1e18;
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

        int256 expectedSwapUnwindValue = 878561643835616438356;
        int256 expectedSwapPayoffToDate = 900 * 1e18;
        uint256 expectedUnwindOpeningFee = 3835616438356164400;

        int256 expectedPayoff = expectedSwapPayoffToDate + expectedSwapUnwindValue - int256(expectedUnwindOpeningFee);

        /// @dev required for spread but in this test we are using mocked spread model
        IporTypes.AccruedIpor memory fakedAccruedIpor;
        IporTypes.MiltonBalancesMemory memory fakedBalance;

        spreadModel.setCalculateQuoteReceiveFixed(1 * 1e16);

        //when
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(swap.id, expectedSwapPayoffToDate, expectedSwapUnwindValue, expectedUnwindOpeningFee);

        vm.prank(_buyer);
        int256 actualPayoff = milton.itfCalculatePayoff(
            swap,
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            swapPayoffToDate,
            fakedAccruedIpor,
            fakedBalance
        );

        //then
        assertEq(actualPayoff, expectedPayoff, "Incorrect payoff");
    }

    function testShouldCalculatePnLForUnwindPayFixedExcel() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        asset = _iporProtocol.asset;
        milton = _iporProtocol.milton;
        spreadModel = _iporProtocol.spreadModel;

        int256 swapPayoffToDate = -180821917808219000000;
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

        int256 expectedSwapUnwindValue = -749383561643835438356;
        int256 expectedSwapPayoffToDate = -180821917808219000000;
        uint256 expectedUnwindOpeningFee = 38356164383561644000;
        int256 expectedPayoff = expectedSwapPayoffToDate + expectedSwapUnwindValue - int256(expectedUnwindOpeningFee);

        /// @dev required for spread but in this test we are using mocked spread model
        IporTypes.AccruedIpor memory fakedAccruedIpor;
        IporTypes.MiltonBalancesMemory memory fakedBalance;

        spreadModel.setCalculateQuoteReceiveFixed(299 * 1e14);

        //when
        vm.expectEmit(true, true, true, true);
        emit SwapUnwind(swap.id, expectedSwapPayoffToDate, expectedSwapUnwindValue, expectedUnwindOpeningFee);

        vm.prank(_buyer);
        int256 actualPayoff = milton.itfCalculatePayoff(
            swap,
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            closingTimestamp,
            swapPayoffToDate,
            fakedAccruedIpor,
            fakedBalance
        );

        //then
        assertEq(actualPayoff, expectedPayoff, "Incorrect payoff");
    }

    function testShouldCloseAndUnwindPayFixedSwapAsBuyerInMoreThanLast24hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 48075873, "Incorrect buyer balance");
    }

    function testShouldCloseAndUnwindReceiveFixedSwapAsBuyerInMoreThanLast24hours() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

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

        assertEq(buyerBalanceBefore - buyerBalanceAfter, 48075873);
        assertEq(adminBalanceAfter - adminBalanceBefore, 0);
    }
}
