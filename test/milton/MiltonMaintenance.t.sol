// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";

contract MiltonMaintenanceTest is Test, TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.PERCENTAGE_4_18DEC, // 4%
            TestConstants.PERCENTAGE_2_18DEC, // 2%
            1 * TestConstants.D16_INT, // 1%
            1 * TestConstants.D16_INT // 1%
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
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldPauseSmartContractWhenSenderIsAnAdmin() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
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
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        mockCase0MiltonDai.pause();
        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
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
        uint256[] memory swapIds = new uint256[](2);
        swapIds[0] = 1;
        swapIds[1] = 2;
        uint256[] memory emptySwapIds = new uint256[](0);
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // simulate that _userTwo is Joseph
        mockCase0MiltonDai.setJoseph(_userTwo);
        // when
        mockCase0MiltonDai.pause();
        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        mockCase0MiltonDai.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC
        );
        vm.expectRevert("Pausable: paused");
        vm.startPrank(_userOne);
        mockCase0MiltonDai.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_1_18DEC, TestConstants.LEVERAGE_18DEC
        );
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.closeSwapPayFixed(1);
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.closeSwapReceiveFixed(1);
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.closeSwaps(swapIds, emptySwapIds);
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.closeSwaps(emptySwapIds, swapIds);
        vm.expectRevert("Pausable: paused");
        vm.stopPrank();
        vm.startPrank(_userTwo);
        mockCase0MiltonDai.depositToStanley(1);
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.withdrawFromStanley(1);
        vm.expectRevert("Pausable: paused");
        vm.stopPrank();
        mockCase0MiltonDai.setupMaxAllowanceForAsset(_userThree);
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.setJoseph(_userThree);
        vm.expectRevert("Pausable: paused");
        mockCase0MiltonDai.setMiltonSpreadModel(_userThree);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
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
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_50_000_18DEC, block.timestamp);
        vm.startPrank(_userTwo);
        mockCase0MiltonDai.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        IporTypes.IporSwapMemory memory swapPayFixed = miltonStorageDai.getSwapPayFixed(1);
        mockCase0MiltonDai.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
        IporTypes.IporSwapMemory memory swapReceiveFixed = miltonStorageDai.getSwapReceiveFixed(1);
        vm.stopPrank();
        // when
        mockCase0MiltonDai.pause();
        // then
        bool paused = mockCase0MiltonDai.paused();
        vm.startPrank(_userOne);
        mockCase0MiltonDai.getVersion();
        mockCase0MiltonDai.getAccruedBalance();
        mockCase0MiltonDai.calculateSpread();
        mockCase0MiltonDai.calculateSoap();
        mockCase0MiltonDai.calculateSoapAtTimestamp(block.timestamp);
        mockCase0MiltonDai.calculatePayoffPayFixed(swapPayFixed);
        mockCase0MiltonDai.calculatePayoffReceiveFixed(swapReceiveFixed);
        mockCase0MiltonDai.getMiltonSpreadModel();
        mockCase0MiltonDai.getMaxSwapCollateralAmount();
        mockCase0MiltonDai.getMaxLpUtilizationRate();
        mockCase0MiltonDai.getMaxLpUtilizationPerLegRate();
        mockCase0MiltonDai.getIncomeFeeRate();
        mockCase0MiltonDai.getOpeningFeeRate();
        mockCase0MiltonDai.getOpeningFeeTreasuryPortionRate();
        mockCase0MiltonDai.getIporPublicationFee();
        mockCase0MiltonDai.getLiquidationDepositAmount();
        mockCase0MiltonDai.getMaxLeverage();
        mockCase0MiltonDai.getMinLeverage();
        mockCase0MiltonDai.getJoseph();
        vm.stopPrank();
        assertTrue(paused);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAdmin() public {
        //given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
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
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
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
        iporOracle.itfUpdateIndex(address(_daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_50_000_18DEC, block.timestamp);
        mockCase0MiltonDai.pause();
        vm.expectRevert("Pausable: paused");
        vm.prank(_userTwo);
        mockCase0MiltonDai.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // when
        mockCase0MiltonDai.unpause();
        vm.startPrank(_userTwo);
        mockCase0MiltonDai.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, TestConstants.PERCENTAGE_6_18DEC, TestConstants.LEVERAGE_18DEC
        );
        // then
        IporTypes.IporSwapMemory memory swapPayFixed = miltonStorageDai.getSwapPayFixed(1);
        vm.stopPrank();
        assertEq(9967009897030890732780, swapPayFixed.collateral);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
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
        mockCase0MiltonDai.pause();
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        mockCase0MiltonDai.unpause();
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();

        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );

        // when
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        mockCase0MiltonDai.confirmTransferOwnership();
        // then
        vm.prank(_userOne);
        address newOwner = mockCase0MiltonDai.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
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
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        mockCase0MiltonDai.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        mockCase0MiltonDai.transferOwnership(_userTwo);
        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        mockCase0MiltonDai.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
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
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        mockCase0MiltonDai.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        mockCase0MiltonDai.confirmTransferOwnership();
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        mockCase0MiltonDai.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        mockCase0MiltonDai.confirmTransferOwnership();
        vm.expectRevert("Ownable: caller is not the owner");
        mockCase0MiltonDai.transferOwnership(_userThree);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(_daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        // when
        mockCase0MiltonDai.transferOwnership(_userTwo);
        mockCase0MiltonDai.transferOwnership(_userTwo);
        vm.prank(_userOne);
        // then
        address actualOwner = mockCase0MiltonDai.owner();
        assertEq(actualOwner, address(_admin));
    }

    function testShouldNotSendEthToMiltonDaiUsdctUsdc() public payable {
        address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
        ItfIporOracle iporOracle = getIporOracleAssets(_userOne, tokenAddresses, uint32(block.timestamp), TestConstants.TC_5_EMA_18DEC_64UINT, 0);
        address[] memory mockCase1StanleyAddresses = addressesToArray(
            address(getMockCase1Stanley(address(_usdtMockedToken))),
            address(getMockCase1Stanley(address(_usdcMockedToken))),
            address(getMockCase1Stanley(address(_daiMockedToken)))
        );
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
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
        address(mockCase0Miltons.mockCase0MiltonUsdt).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Miltons.mockCase0MiltonUsdc).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Miltons.mockCase0MiltonDai).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonStorageDaiUsdctUsdc() public payable {
        MiltonStorages memory miltonStorages = getMiltonStorages();
        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(miltonStorages.miltonStorageUsdt).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(miltonStorages.miltonStorageUsdc).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(miltonStorages.miltonStorageDai).call{value: msg.value}("");
    }
}
