// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {BuilderUtils} from "../utils/builder/BuilderUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/mocks/ammTreasury/MockAmmStorage.sol";

contract AmmTreasuryShouldNotOpenPositionTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

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
        _cfg.iporRiskManagementOracleUpdater = _userOne;

        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .DEFAULT;
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooLow() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_310");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(TestConstants.ZERO, 3, TestConstants.LEVERAGE_18DEC);
    }

    function testShouldNotOpenPositionWhenTotalAmountIsGreaterThanAssetBalance() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_003");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.USER_SUPPLY_10MLN_18DEC + 3,
            3,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed18Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            30000000000000000001,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInReceiveFixed18Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            30000000000000000001,
            TestConstants.D16 + 48374213950104766,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInPayFixed6Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            30000001,
            39999999999999999,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenAcceptableFixedInterestRateIsExceededInReceiveFixed6Decimals() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);

        // when
        vm.expectRevert("IPOR_313");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            30000001,
            48374213950069062 + TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooHighCaseOne() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_312");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            1000000000000000000000001,
            3,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsTooHighCaseTwo() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_312");
        _iporProtocol.ammTreasury.openSwapPayFixed(
            100688870576704582165765,
            3,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenLiquidityPoolBalanceIsTooLow() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        uint256 endTimestamp = block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS;

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_1_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.USD_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(address(_iporProtocol.asset), 16 * TestConstants.D17, block.timestamp);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            endTimestamp
        );
        vm.stopPrank();

        _iporProtocol.ammStorage.setJoseph(_userOne);

        vm.prank(_userOne);
        _iporProtocol.ammStorage.subtractLiquidityInternal(20000 * TestConstants.D18);
        _iporProtocol.ammStorage.setJoseph(address(_iporProtocol.joseph));

        // when
        vm.expectRevert("IPOR_320");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.itfCloseSwapPayFixed(1, endTimestamp);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);
    }

    function testShouldNotOpenPayFixedPositionWhenLeverageIsTooLow() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_308");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            500
        );
    }

    function testShouldNotOpenPayFixedPositionWhenLeverageIsTooHigh() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);
        // when
        vm.expectRevert("IPOR_309");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            1000000000000000000001
        );
    }

    function testShouldNotOpenPositionWhenCollateralRatioIsExceeded() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE7;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        // when
        vm.expectRevert("IPOR_302");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_100_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenRiskManagementOracleProvidesZeroCollateralRatio() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE7;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(50 * TestConstants.USD_28_000_18DEC);

        // when
        vm.expectRevert("IPOR_302");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_100_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotOpenPositionWhenRiskManagementOracleProvidesZeroNotionalAndLeverageIsHigherThan10() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE7;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(50 * TestConstants.USD_28_000_18DEC);
        // when
        vm.expectRevert("IPOR_309");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_100_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_11_18DEC
        );
    }

    function testShouldNotOpenPositionWhenRiskManagementOracleProvidesMaxNotional() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE7;
        _cfg.iporRiskManagementOracleInitialParamsTestCase = BuilderUtils
            .IporRiskManagementOracleInitialParamsTestCase
            .CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(50 * TestConstants.USD_28_000_18DEC);
        // when
        vm.expectRevert("IPOR_309");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_100_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_1001_18DEC
        );
    }

    function testShouldNotOpenPositionWhenTotalAmountIsLowerThanFee() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE8;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        // when
        vm.expectRevert("IPOR_311");
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldNotGetAmmTreasuryAccruedBalanceWhenLiquidityPoolAmountIsTooLow() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE8;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_2_18DEC);

        MockAmmStorage mockAmmStorage = new MockAmmStorage();

        MockAmmTreasury(address(_iporProtocol.ammTreasury)).setMockAmmStorage(address(mockAmmStorage));

        // when
        vm.expectRevert("IPOR_301");
        _iporProtocol.ammTreasury.getAccruedBalance();
    }
}
