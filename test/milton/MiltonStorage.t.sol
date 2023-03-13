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
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/interfaces/types/MiltonStorageTypes.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract MiltonStorageTest is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    address internal _miltonStorageAddress;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.PERCENTAGE_4_18DEC,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _miltonStorageAddress = _getUserAddress(5);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        // when
        miltonStorageDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        miltonStorageDai.confirmTransferOwnership();
        // then
        vm.prank(_userOne);
        address newOwner = miltonStorageDai.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        miltonStorageDai.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        // when
        miltonStorageDai.transferOwnership(_userTwo);
        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        miltonStorageDai.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        // when
        miltonStorageDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        miltonStorageDai.confirmTransferOwnership();
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        miltonStorageDai.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        // when
        miltonStorageDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        miltonStorageDai.confirmTransferOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        miltonStorageDai.transferOwnership(_userThree);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        // when
        miltonStorageDai.transferOwnership(_userTwo);
        miltonStorageDai.transferOwnership(_userTwo);
        vm.prank(_userOne);
        // then
        address actualOwner = miltonStorageDai.owner();
        assertEq(actualOwner, _admin);
    }

    function testShouldUpdateMiltonStorageWhenOpenPositionAndCallerHasRightsToUpdate() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley mockCase1StanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(mockCase1StanleyDai)
        );
        miltonStorageDai.setMilton(_miltonStorageAddress);
        AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);
        uint256 iporPublicationFee = mockCase0MiltonDai.getIporPublicationFee();
        // when
        vm.prank(_miltonStorageAddress);
        uint256 swapId = miltonStorageDai.updateStorageWhenOpenSwapPayFixed(newSwap, iporPublicationFee);
        // then
        assertEq(swapId, 1);
    }

    function testShouldNotUpdateMiltonStorageWhenOpenPositionAndCallerDoesNotHaveRightsToUpdate() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        miltonStorageDai.setMilton(_miltonStorageAddress);
        AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);
        uint256 iporPublicationFee = mockCase0MiltonDai.getIporPublicationFee();
        // when
        vm.expectRevert("IPOR_008");
        vm.prank(_userThree);
        miltonStorageDai.updateStorageWhenOpenSwapPayFixed(newSwap, iporPublicationFee);
    }

    function testShouldNotAddLiquidityWhenAssetAmountIsZero() public {
        //given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        miltonStorageDai.setJoseph(_liquidityProvider);
        // when
        vm.expectRevert("IPOR_328");
        vm.prank(_liquidityProvider);
        miltonStorageDai.addLiquidity(
            _liquidityProvider,
            TestConstants.ZERO,
            TestConstants.USD_10_000_000_18DEC,
            TestConstants.USD_10_000_000_18DEC
        );
    }

    function testShouldNotUpdateStorageWhenTransferredAmountToTreasuryIsGreaterThanBalance() public {
        //given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        miltonStorageDai.setJoseph(_liquidityProvider);
        // when
        vm.expectRevert("IPOR_330");
        vm.prank(_liquidityProvider);
        miltonStorageDai.updateStorageWhenTransferToTreasury(TestConstants.D18 * TestConstants.D18);
    }

    function testShouldNotUpdateStorageWhenVaultBalanceIsLowerThanDepositAmount() public {
        //given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        miltonStorageDai.setMilton(_miltonStorageAddress);
        // when
        vm.expectRevert("IPOR_329");
        vm.prank(_miltonStorageAddress);
        miltonStorageDai.updateStorageWhenDepositToStanley(TestConstants.D18, TestConstants.ZERO);
    }

    function testShouldNotUpdateStorageWhenTransferredAmountToCharliesGreaterThanBalacer() public {
        //given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        miltonStorageDai.setJoseph(_liquidityProvider);
        // when
        vm.expectRevert("IPOR_326");
        vm.prank(_liquidityProvider);
        miltonStorageDai.updateStorageWhenTransferToCharlieTreasury(TestConstants.D18 * TestConstants.D18);
    }

    function testShouldNotUpdateStorageWhenSendZero() public {
        //given
        MiltonStorage miltonStorageDai = getMiltonStorage();
        miltonStorageDai.setJoseph(_liquidityProvider);
        // when
        vm.expectRevert("IPOR_006");
        vm.prank(_liquidityProvider);
        miltonStorageDai.updateStorageWhenTransferToCharlieTreasury(TestConstants.ZERO);
    }

    function testShouldUpdateMiltonStorageWhenClosePositionAndCallerHasRightsToUpdateDAI18Decimals() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        miltonStorageDai.setMilton(_miltonStorageAddress);
        vm.prank(address(mockCase0MiltonDai));
        IporTypes.IporSwapMemory memory derivativeItem = miltonStorageDai.getSwapPayFixed(1);
        // when
        vm.prank(_miltonStorageAddress);
        miltonStorageDai.updateStorageWhenCloseSwapPayFixed(
            address(_userTwo),
            derivativeItem,
            10 * TestConstants.D18_INT,
            1 * TestConstants.D18,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            95 * TestConstants.D16,
            TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        miltonStorageDai.setMilton(address(mockCase0MiltonDai));
    }

    function testShouldUpdateMiltonStorageWhenClosePositionAndCallerHasRightsToUpdateUSDT6Decimals() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonUsdt
        );
        miltonStorageUsdt.setMilton(_miltonStorageAddress);
        vm.prank(address(mockCase0MiltonUsdt));
        IporTypes.IporSwapMemory memory derivativeItem = miltonStorageUsdt.getSwapPayFixed(1);
        // when
        vm.prank(_miltonStorageAddress);
        miltonStorageUsdt.updateStorageWhenCloseSwapPayFixed(
            address(_userTwo),
            derivativeItem,
            10 * TestConstants.D18_INT,
            1 * TestConstants.D18,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            95 * TestConstants.D16,
            TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
        miltonStorageUsdt.setMilton(address(mockCase0MiltonUsdt));
    }

    function testShouldNotUpdateMiltonStorageWhenClosePositionAndCallerDoesNotHaveRightsToUpdate() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        openSwapPayFixed(
            _userTwo,
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            mockCase0MiltonDai
        );
        miltonStorageDai.setMilton(_miltonStorageAddress);
        vm.prank(address(mockCase0MiltonDai));
        IporTypes.IporSwapMemory memory derivativeItem = miltonStorageDai.getSwapPayFixed(1);
        // when
        vm.expectRevert("IPOR_008");
        vm.prank(_userThree);
        miltonStorageDai.updateStorageWhenCloseSwapPayFixed(
            address(_userTwo),
            derivativeItem,
            10 * TestConstants.D18_INT,
            1 * TestConstants.D18,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS,
            95 * TestConstants.D16,
            TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testGetSwapsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, TestConstants.ZERO);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, 10, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 11, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, 11);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, 10, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, 20, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 2);
    }

    function testGetSwapsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 20, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsPayFixed(_userTwo, 20, 10);
        // then
        assertEq(totalCount, 20);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 0, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, TestConstants.ZERO);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 0, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 10, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 11, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 10, 10);
        // then
        assertEq(totalCount, 11);
        assertEq(swaps.length, 1);
    }

    function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 10, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) =
            miltonStorageUsdt.getSwapsReceiveFixed(_userTwo, 20, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 2);
    }

    function testGetSwapIdsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 0, 0);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) =
            miltonStorageUsdt.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 10, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 11, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) =
            miltonStorageUsdt.getSwapPayFixedIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, 11);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 10, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 20, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 2);
    }

    function testGetSwapIdsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 20, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapPayFixedIds(_userTwo, 20, 10);
        // then
        assertEq(totalCount, 20);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, uint256[] memory ids) =
            miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, TestConstants.ZERO, TestConstants.ZERO);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) =
            miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 10, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 11, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 10, 10);
        // then
        assertEq(totalCount, 11);
        assertEq(ids.length, 1);
    }

    function testGetSwapIdsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 10, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 22, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, uint256[] memory ids) = miltonStorageUsdt.getSwapReceiveFixedIds(_userTwo, 20, 10);
        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 2);
    }

    function testGetSwapIdsShouldFailWhenPageSizeIsEqualToZero() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, TestConstants.ZERO, TestConstants.ZERO);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, 10, 10);
        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnPayFixedSwapsWhenUserDoesNotHaveReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 5, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, 5);
        assertEq(ids.length, 5);
    }

    function testGetSwapIdsShouldReturnReceiveFixedSwapsWhenUserDoesNotHavePayFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, TestConstants.ZERO, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 5, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, 5);
        assertEq(ids.length, 5);
    }

    function testGetSwapIdsShouldReturn6SwapsWhenUserHas3PayFixedSwapsAnd3ReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 3, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 3, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, 6);
        assertEq(ids.length, 6);
    }

    function testGetSwapIdsShouldReturnLimited10SwapsWhenUserHas9PayFixedSwapsAnd12ReceiveFixedSwapsAndOffsetZeroAndPageSize10(
    ) public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 9, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 12, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, TestConstants.ZERO, 10);
        // then
        assertEq(totalCount, 21);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsShouldReturnEmptyArrayWhenUserHasMoreSwapsThanPageSizeAndOffset80AndPageSize10() public {
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase1Stanley stanleyUsdt = getMockCase1Stanley(address(_usdtMockedToken));
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp);
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_50_000_6DEC, block.timestamp);
        iterateOpenSwapsPayFixed(
            _userTwo, mockCase0MiltonUsdt, 9, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo, mockCase0MiltonUsdt, 12, TestConstants.USD_100_6DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        (uint256 totalCount, MiltonStorageTypes.IporSwapId[] memory ids) =
            miltonStorageUsdt.getSwapIds(_userTwo, 80, 10);
        // then
        assertEq(totalCount, 21);
        assertEq(ids.length, TestConstants.ZERO);
    }
}