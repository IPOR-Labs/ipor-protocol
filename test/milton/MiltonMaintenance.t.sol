// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/UsdcMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/amm/MiltonStorage.sol";

contract MiltonMaintenanceTest is
    Test,
    TestCommons,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    IporOracleUtils,
    DataUtils,
    SwapUtils,
    StanleyUtils
{
    MockSpreadModel internal _miltonSpreadModel;
    UsdtMockedToken internal _usdtMockedToken;
    UsdcMockedToken internal _usdcMockedToken;
    DaiMockedToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            4 * 10 ** 16, // 4%
            2 * 10 ** 16, // 2%
            1 * 10 ** 16, // 1%
            1 * 10 ** 16 // 1%
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
    }

    function testShouldPauseSmartContractWhenSenderIsAnAdmin() public {
        //given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.pause();
        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.openSwapPayFixed(10000 * Constants.D18, 6 * 10 ** 16, 10 * Constants.D18);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        //given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        uint256[] memory swapIds = new uint256[](2);
        swapIds[0] = 1;
        swapIds[1] = 2;
        uint256[] memory emptySwapIds = new uint256[](0);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        // simulate that _userTwo is Joseph
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.setJoseph(_userTwo);
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.pause();
        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.openSwapPayFixed(10000 * Constants.D18, 6 * 10 ** 16, 10 * Constants.D18);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.openSwapReceiveFixed(10000 * Constants.D18, 1 * 10 ** 16, 10 * Constants.D18);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.closeSwapPayFixed(1);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.closeSwapReceiveFixed(1);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.closeSwaps(swapIds, emptySwapIds);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.closeSwaps(emptySwapIds, swapIds);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        mockCase0MiltonDai.depositToStanley(1);
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        mockCase0MiltonDai.withdrawFromStanley(1);
        vm.expectRevert("Pausable: paused");
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.setupMaxAllowanceForAsset(_userThree);
        vm.expectRevert("Pausable: paused");
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.setJoseph(_userThree);
        vm.expectRevert("Pausable: paused");
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.setMiltonSpreadModel(_userThree);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        //given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(50000 * Constants.D18, block.timestamp); // USD_50_000_18DEC
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(block.timestamp, 10000 * Constants.D18, 6 * 10 ** 16, 10 * Constants.D18);
        vm.prank(_userTwo);
        IporTypes.IporSwapMemory memory swapPayFixed = miltonStorageDai.getSwapPayFixed(1);
        vm.prank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, 10000 * Constants.D18, 1 * 10 ** 16, 10 * Constants.D18
        );
        vm.prank(_userTwo);
        IporTypes.IporSwapMemory memory swapReceiveFixed = miltonStorageDai.getSwapReceiveFixed(1);
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.pause();
        // then
        vm.prank(address(mockCase0MiltonDaiProxy));
        bool paused = mockCase0MiltonDai.paused();
        vm.prank(_userOne);
        mockCase0MiltonDai.getVersion();
        vm.prank(_userOne);
        mockCase0MiltonDai.getAccruedBalance();
        vm.prank(_userOne);
        mockCase0MiltonDai.calculateSpread();
        vm.prank(_userOne);
        mockCase0MiltonDai.calculateSoap();
        vm.prank(_userOne);
        mockCase0MiltonDai.calculateSoapAtTimestamp(block.timestamp);
        vm.prank(_userOne);
        mockCase0MiltonDai.calculatePayoffPayFixed(swapPayFixed);
        vm.prank(_userOne);
        mockCase0MiltonDai.calculatePayoffReceiveFixed(swapReceiveFixed);
        vm.prank(_userOne);
        mockCase0MiltonDai.getMiltonSpreadModel();
        vm.prank(_userOne);
        mockCase0MiltonDai.getMaxSwapCollateralAmount();
        vm.prank(_userOne);
        mockCase0MiltonDai.getMaxLpUtilizationRate();
        vm.prank(_userOne);
        mockCase0MiltonDai.getMaxLpUtilizationPerLegRate();
        vm.prank(_userOne);
        mockCase0MiltonDai.getIncomeFeeRate();
        vm.prank(_userOne);
        mockCase0MiltonDai.getOpeningFeeRate();
        vm.prank(_userOne);
        mockCase0MiltonDai.getOpeningFeeTreasuryPortionRate();
        vm.prank(_userOne);
        mockCase0MiltonDai.getIporPublicationFee();
        vm.prank(_userOne);
        mockCase0MiltonDai.getLiquidationDepositAmount();
        vm.prank(_userOne);
        mockCase0MiltonDai.getMaxLeverage();
        vm.prank(_userOne);
        mockCase0MiltonDai.getMinLeverage();
        vm.prank(_userOne);
        mockCase0MiltonDai.getJoseph();
        assertTrue(paused);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAdmin() public {
        //given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(_userThree));
        mockCase0MiltonDai.pause();
    }

    function testShouldUnpauseSmartContractWhenSenderIsAdmin() public {
        //given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PER
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(50000 * Constants.D18, block.timestamp); // USD_50_000_18DEC
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.pause();
        vm.expectRevert("Pausable: paused");
        vm.prank(address(_userTwo));
        mockCase0MiltonDai.openSwapPayFixed(10000 * Constants.D18, 6 * 10 ** 16, 10 * Constants.D18);
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.unpause();
        vm.prank(address(_userTwo));
        mockCase0MiltonDai.openSwapPayFixed(10000 * Constants.D18, 6 * 10 ** 16, 10 * Constants.D18);
        // then
        vm.prank(_userTwo);
        IporTypes.IporSwapMemory memory swapPayFixed = miltonStorageDai.getSwapPayFixed(1);
        assertEq(9967009897030890732780, swapPayFixed.collateral);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.pause();
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        mockCase0MiltonDai.unpause();
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        mockCase0MiltonDai.confirmTransferOwnership();
        // then
        vm.prank(address(_userOne));
        address newOwner = mockCase0MiltonDai.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester mockCase0JosephDaiProxy, MockCase0JosephDai mockCase0JosephDai) = getMockCase0JosephDai(
            _admin,
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMiltonStorage(
            miltonStorageDai, miltonStorageDaiProxy, address(mockCase0JosephDai), address(mockCase0MiltonDai)
        );
        prepareMockCase0MiltonDai(
            mockCase0MiltonDai, address(mockCase0MiltonDaiProxy), address(mockCase0JosephDai), address(stanleyDai)
        );
        prepareMockCase0JosephDai(mockCase0JosephDai, address(mockCase0JosephDaiProxy));
        prepareIpTokenDai(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        mockCase0MiltonDai.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        mockCase0MiltonDai.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        mockCase0MiltonDai.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointerdOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        mockCase0MiltonDai.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        mockCase0MiltonDai.confirmTransferOwnership();
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        mockCase0MiltonDai.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        mockCase0MiltonDai.confirmTransferOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userThree);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester mockCase0MiltonDaiProxy, MockCase0MiltonDai mockCase0MiltonDai) = getMockCase0MiltonDai(
            _admin,
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(address(mockCase0MiltonDaiProxy));
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userOne);
        // then
        address actualOwner = mockCase0MiltonDai.owner();
        assertEq(actualOwner, address(mockCase0MiltonDaiProxy));
    }

    function testShouldNotSendEthToMiltonDaiUsdctUsdc() public payable {
        address[] memory tokenAddresses =
            getTokenAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        ItfIporOracle iporOracle =
            getIporOracleThreeAssets(_admin, _userOne, tokenAddresses, uint32(block.timestamp), 5 * 10 ** 16, 0);
        address[] memory mockCase1StanleyAddresses =
            getMockCase1StanleyAddresses(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        address[] memory miltonStorageAddresses = getMiltonStorageAddresses(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            _admin,
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Miltons.mockCase0MiltonUsdtProxy).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Miltons.mockCase0MiltonUsdcProxy).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Miltons.mockCase0MiltonDaiProxy).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonStorageDaiUsdctUsdc() public payable {
        MiltonStorages memory miltonStorages = getMiltonStorages(_admin);
        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(miltonStorages.miltonStorageUsdtProxy).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(miltonStorages.miltonStorageUsdcProxy).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(miltonStorages.miltonStorageDaiProxy).call{value: msg.value}("");
    }
}
