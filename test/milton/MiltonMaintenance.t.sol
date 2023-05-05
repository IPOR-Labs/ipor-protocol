// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

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

contract MiltonMaintenanceTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.TestCaseConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    event MiltonSpreadModelChanged(
        address indexed changedBy,
        address indexed oldMiltonSpreadModel,
        address indexed newMiltonSpreadModel
    );

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
    }

    function testShouldPauseSmartContractWhenSenderIsAnAdmin() public {
        //given
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
        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        _iporProtocol.milton.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        //given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256[] memory swapIds = new uint256[](2);
        swapIds[0] = 1;
        swapIds[1] = 2;
        uint256[] memory emptySwapIds = new uint256[](0);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.startPrank(_admin);
        _iporProtocol.milton.setJoseph(_userTwo);

        // when
        _iporProtocol.milton.pause();
        vm.stopPrank();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        _iporProtocol.milton.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.expectRevert("Pausable: paused");
        vm.startPrank(_userOne);
        _iporProtocol.milton.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.closeSwapPayFixed(1);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.closeSwapReceiveFixed(1);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.closeSwaps(swapIds, emptySwapIds);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.closeSwaps(emptySwapIds, swapIds);
        vm.stopPrank();

        vm.startPrank(_userTwo);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.depositToStanley(1);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.withdrawFromStanley(1);
        vm.stopPrank();

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.setupMaxAllowanceForAsset(_userThree);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.setJoseph(_userThree);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.milton.setMiltonSpreadModel(_userThree);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        //given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_50_000_18DEC, block.timestamp);

        vm.startPrank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.IporSwapMemory memory swapPayFixed = _iporProtocol.miltonStorage.getSwapPayFixed(
            1
        );
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.IporSwapMemory memory swapReceiveFixed = _iporProtocol
            .miltonStorage
            .getSwapReceiveFixed(1);
        vm.stopPrank();

        // when
        vm.startPrank(_admin);
        _iporProtocol.milton.pause();

        // then
        bool paused = _iporProtocol.milton.paused();
        vm.stopPrank();

        vm.startPrank(_userOne);
        _iporProtocol.milton.getVersion();
        _iporProtocol.milton.getAccruedBalance();
        _iporProtocol.milton.calculateSpread();
        _iporProtocol.milton.calculateSoap();
        _iporProtocol.milton.calculateSoapAtTimestamp(block.timestamp);
        _iporProtocol.milton.calculatePayoffPayFixed(swapPayFixed);
        _iporProtocol.milton.calculatePayoffReceiveFixed(swapReceiveFixed);
        _iporProtocol.milton.getMiltonSpreadModel();
        _iporProtocol.milton.getMaxSwapCollateralAmount();
        _iporProtocol.milton.getMaxLpUtilizationRate();
        _iporProtocol.milton.getMaxLpUtilizationPerLegRate();
        _iporProtocol.milton.getIncomeFeeRate();
        _iporProtocol.milton.getOpeningFeeRate();
        _iporProtocol.milton.getOpeningFeeTreasuryPortionRate();
        _iporProtocol.milton.getIporPublicationFee();
        _iporProtocol.milton.getLiquidationDepositAmount();
        _iporProtocol.milton.getMaxLeverage();
        _iporProtocol.milton.getMinLeverage();
        _iporProtocol.milton.getJoseph();
        vm.stopPrank();
        assertTrue(paused);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAdmin() public {
        //given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(_userThree));
        _iporProtocol.milton.pause();
    }

    function testShouldUnpauseSmartContractWhenSenderIsAdmin() public {
        //given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_50_000_18DEC, block.timestamp);

        vm.prank(_admin);
        _iporProtocol.milton.pause();
        vm.expectRevert("Pausable: paused");

        vm.prank(_userTwo);
        _iporProtocol.milton.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_admin);
        _iporProtocol.milton.unpause();

        vm.startPrank(_userTwo);
        _iporProtocol.milton.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // then
        IporTypes.IporSwapMemory memory swapPayFixed = _iporProtocol.miltonStorage.getSwapPayFixed(
            1
        );
        vm.stopPrank();
        assertEq(9967009897030890732780, swapPayFixed.collateral);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.milton.pause();

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        _iporProtocol.milton.unpause();
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        _iporProtocol.milton.confirmTransferOwnership();

        // then
        vm.prank(_userOne);
        address newOwner = _iporProtocol.milton.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        _iporProtocol.milton.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderIsNotAppointedOwner() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.transferOwnership(_userTwo);

        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        _iporProtocol.milton.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderIsNotAppointedOwner() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.milton.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.milton.confirmTransferOwnership();

        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        _iporProtocol.milton.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.milton.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.milton.confirmTransferOwnership();

        // when
        vm.prank(_admin);
        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.milton.transferOwnership(_userTwo);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.startPrank(_admin);
        _iporProtocol.milton.transferOwnership(_userTwo);

        // when
        _iporProtocol.milton.transferOwnership(_userTwo);
        vm.stopPrank();

        // then
        vm.prank(_userOne);
        address actualOwner = _iporProtocol.milton.owner();
        assertEq(actualOwner, address(_admin));
    }

    function testShouldNotSendEthToMiltonDai() public payable {
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.milton).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonUsdt() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.milton).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonUsdc() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.milton).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonStorageDai() public payable {
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.miltonStorage).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonStorageUsdt() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.miltonStorage).call{value: msg.value}("");
    }

    function testShouldNotSendEthToMiltonStorageUsdc() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.miltonStorage).call{value: msg.value}("");
    }

    function testShouldEmitMiltonSpreadModelChanged() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        address oldMiltonSpreadModel = _iporProtocol.milton.getMiltonSpreadModel();
        address newMiltonSpreadModel = address(_userThree);

        // when
        vm.expectEmit(true, true, true, true);
        emit MiltonSpreadModelChanged(_admin, oldMiltonSpreadModel, newMiltonSpreadModel);
        _iporProtocol.milton.setMiltonSpreadModel(newMiltonSpreadModel);
    }
}
