// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/interfaces/types/IporTypes.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";

contract AmmTreasuryMaintenanceTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    event AmmTreasurySpreadModelChanged(
        address indexed changedBy,
        address indexed oldAmmTreasurySpreadModel,
        address indexed newAmmTreasurySpreadModel
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
        _cfg.iporRiskManagementOracleUpdater = _userOne;

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
        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        //given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
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
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.startPrank(_admin);
        _iporProtocol.ammTreasury.setJoseph(_userTwo);

        // when
        _iporProtocol.ammTreasury.pause();
        vm.stopPrank();

        // then
        vm.expectRevert("Pausable: paused");
        vm.prank(_userOne);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.expectRevert("Pausable: paused");
        vm.startPrank(_userOne);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.closeSwapPayFixed(1);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.closeSwapReceiveFixed(1);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.closeSwaps(swapIds, emptySwapIds);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.closeSwaps(emptySwapIds, swapIds);
        vm.stopPrank();

        vm.startPrank(_userTwo);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.depositToAssetManagement(1);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.withdrawFromAssetManagement(1);
        vm.stopPrank();

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.setupMaxAllowanceForAsset(_userThree);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.setJoseph(_userThree);

        vm.expectRevert("Pausable: paused");
        _iporProtocol.ammTreasury.setAmmTreasurySpreadModel(_userThree);
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        //given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_50_000_18DEC);

        vm.startPrank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.IporSwapMemory memory swapPayFixed = _iporProtocol.ammStorage.getSwapPayFixed(1);
        _iporProtocol.ammTreasury.openSwapReceiveFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.IporSwapMemory memory swapReceiveFixed = _iporProtocol.ammStorage.getSwapReceiveFixed(1);
        vm.stopPrank();

        // when
        vm.startPrank(_admin);
        _iporProtocol.ammTreasury.pause();

        // then
        bool paused = _iporProtocol.ammTreasury.paused();
        vm.stopPrank();

        vm.startPrank(_userOne);
        _iporProtocol.ammTreasury.getVersion();
        _iporProtocol.ammTreasury.getAccruedBalance();
        _iporProtocol.ammTreasury.calculateSpread();
        _iporProtocol.ammTreasury.calculateSoap();
        _iporProtocol.ammTreasury.calculateSoapAtTimestamp(block.timestamp);
        _iporProtocol.ammTreasury.calculatePayoffPayFixed(swapPayFixed);
        _iporProtocol.ammTreasury.calculatePayoffReceiveFixed(swapReceiveFixed);
        _iporProtocol.ammTreasury.getAmmTreasurySpreadModel();
        _iporProtocol.ammTreasury.getMaxSwapCollateralAmount();
        _iporProtocol.ammTreasury.getMaxLpUtilizationRate();
        _iporProtocol.ammTreasury.getMaxLpUtilizationPerLegRate();
        _iporProtocol.ammTreasury.getOpeningFeeRate();
        _iporProtocol.ammTreasury.getOpeningFeeTreasuryPortionRate();
        _iporProtocol.ammTreasury.getIporPublicationFee();
        _iporProtocol.ammTreasury.getLiquidationDepositAmount();
        _iporProtocol.ammTreasury.getMaxLeverage();
        _iporProtocol.ammTreasury.getMinLeverage();
        _iporProtocol.ammTreasury.getJoseph();
        vm.stopPrank();
        assertTrue(paused);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAdmin() public {
        //given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(_userThree));
        _iporProtocol.ammTreasury.pause();
    }

    function testShouldUnpauseSmartContractWhenSenderIsAdmin() public {
        //given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.TC_50_000_18DEC);

        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();
        vm.expectRevert("Pausable: paused");

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.unpause();

        vm.startPrank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // then
        IporTypes.IporSwapMemory memory swapPayFixed = _iporProtocol.ammStorage.getSwapPayFixed(1);
        vm.stopPrank();
        assertEq(TestConstants.TC_COLLATERAL_18DEC, swapPayFixed.collateral);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.ammTreasury.pause();

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.unpause();
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.confirmTransferOwnership();

        // then
        vm.prank(_userOne);
        address newOwner = _iporProtocol.ammTreasury.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderIsNotAppointedOwner() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);

        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderIsNotAppointedOwner() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.confirmTransferOwnership();

        // then
        vm.expectRevert("IPOR_007");
        vm.prank(_userThree);
        _iporProtocol.ammTreasury.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.confirmTransferOwnership();

        // when
        vm.prank(_admin);
        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.startPrank(_admin);
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);

        // when
        _iporProtocol.ammTreasury.transferOwnership(_userTwo);
        vm.stopPrank();

        // then
        vm.prank(_userOne);
        address actualOwner = _iporProtocol.ammTreasury.owner();
        assertEq(actualOwner, address(_admin));
    }

    function testShouldNotSendEthToAmmTreasuryDai() public payable {
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.ammTreasury).call{value: msg.value}("");
    }

    function testShouldNotSendEthToAmmTreasuryUsdt() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.ammTreasury).call{value: msg.value}("");
    }

    function testShouldNotSendEthToAmmTreasuryUsdc() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.ammTreasury).call{value: msg.value}("");
    }

    function testShouldNotSendEthToAmmStorageDai() public payable {
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.ammStorage).call{value: msg.value}("");
    }

    function testShouldNotSendEthToAmmStorageUsdt() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.ammStorage).call{value: msg.value}("");
    }

    function testShouldNotSendEthToAmmStorageUsdc() public payable {
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.ammStorage).call{value: msg.value}("");
    }

    function testShouldEmitAmmTreasurySpreadModelChanged() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        address oldAmmTreasurySpreadModel = _iporProtocol.ammTreasury.getAmmTreasurySpreadModel();
        address newAmmTreasurySpreadModel = address(_userThree);

        // when
        vm.expectEmit(true, true, true, true);
        emit AmmTreasurySpreadModelChanged(_admin, oldAmmTreasurySpreadModel, newAmmTreasurySpreadModel);
        _iporProtocol.ammTreasury.setAmmTreasurySpreadModel(newAmmTreasurySpreadModel);
    }
}
