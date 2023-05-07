// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase7MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase8MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/mocks/milton/MockMiltonStorage.sol";

contract MiltonShouldNotOpenPositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooLow() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_310");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.ZERO,
            3,
            TestConstants.LEVERAGE_18DEC
        );

    }

    function testShouldNotOpenPositionWhenTotalAmountIsGreaterThanAssetBalance() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_003");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USER_SUPPLY_10MLN_18DEC + 3,
            3,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed18Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            30000000000000000001,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC
        );

    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInReceiveFixed18Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            30000000000000000001,
            TestConstants.D16 + 48374213950104766,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed6Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            30000001,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInReceiveFixed6Decimals()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonUsdt());
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            30000001,
            48374213950069062 + TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooHighCaseOne() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_312");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            1000000000000000000000001,
            3,
            TestConstants.LEVERAGE_18DEC
        );

    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooHighCaseTwo() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_312");
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            100688870576704582165765,
            3,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenLiquidityPoolBalanceIsTooLow() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_1_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.USD_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            16 * TestConstants.D17,
            block.timestamp
        );
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        _iporProtocol.miltonStorage.setJoseph(_userOne);

        vm.prank(_userOne);
        _iporProtocol.miltonStorage.subtractLiquidity(20000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));

        // when
        vm.expectRevert("IPOR_320");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfCloseSwapPayFixed(1, endTimestamp);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
    }

    function testShouldNotOpenPayFixedPositionWhenLeverageIsTooLow() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        // when
        vm.expectRevert("IPOR_308");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            500
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLeverageIsTooHigh() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        // when
        vm.expectRevert("IPOR_309");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            1000000000000000000001
        );
    }

    function testShouldNotOpenPositionWhenUtilizationIsExceeded() public {
        // given
        _cfg.miltonImplementation = address(new MockCase7MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        // when
        vm.expectRevert("IPOR_302");
        vm.prank(_userThree);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsLowerThanFee() public {
        // given
        _cfg.miltonImplementation = address(new MockCase8MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        // when
        vm.expectRevert("IPOR_311");
        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotGetMiltonAccruedBalanceWhenLiquidtyPoolAmountIsTooLow() public {
        // given
        _cfg.miltonImplementation = address(new MockCase8MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        MockMiltonStorage mockMiltonStorage = new MockMiltonStorage();

        MockCase8MiltonDai(address(_iporProtocol.milton)).setMockMiltonStorage(
            address(mockMiltonStorage)
        );

        // when
        vm.expectRevert("IPOR_301");
        _iporProtocol.milton.getAccruedBalance();
    }
}
