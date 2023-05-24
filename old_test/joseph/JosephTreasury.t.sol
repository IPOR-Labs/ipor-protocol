// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/interfaces/types/AmmStorageTypes.sol";
import "contracts/amm/AmmStorage.sol";

contract JosephTreasuryTest is TestCommons, DataUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

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

    function testShouldNotTransferPublicationFeToCharlieTreasuryWhenCallerIsNotPublicationFeeTransferer() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert("IPOR_406");
        vm.prank(_userThree);
        _iporProtocol.joseph.transferToCharlieTreasury(100);
    }

    function testShouldNotTransferPublicationFeToCharlieTreasuryWhenCharlieTreasuryAddressIsIncorrect() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.joseph.setCharlieTreasuryManager(_userThree);
        // when
        vm.expectRevert("IPOR_407");
        vm.prank(_userThree);
        _iporProtocol.joseph.transferToCharlieTreasury(100);
    }

    function testShouldTransferPublicationFeeToCharlieTreasurySimpleCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 transferredAmount = 100;
        uint256 expectedERC20BalanceCharlieTreasury = TestConstants.USER_SUPPLY_10MLN_18DEC + transferredAmount;
        uint256 expectedERC20BalanceAmmTreasury = TestConstants.USD_28_000_18DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC -
            transferredAmount;
        uint256 expectedPublicationFeeBalanceAmmTreasury = TestConstants.USD_10_18DEC - transferredAmount;
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_admin);
        _iporProtocol.joseph.setCharlieTreasuryManager(_userThree);
        _iporProtocol.joseph.setCharlieTreasury(_userOne);
        vm.stopPrank();

        // when
        vm.prank(_userThree);
        _iporProtocol.joseph.transferToCharlieTreasury(transferredAmount);

        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualERC20BalanceCharlieTreasury = _iporProtocol.asset.balanceOf(_userOne);
        uint256 actualERC20BalanceAmmTreasury = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));
        uint256 actualPublicationFeeBalanceAmmTreasury = balance.iporPublicationFee;

        assertEq(actualERC20BalanceCharlieTreasury, expectedERC20BalanceCharlieTreasury);
        assertEq(actualERC20BalanceAmmTreasury, expectedERC20BalanceAmmTreasury);
        assertEq(actualPublicationFeeBalanceAmmTreasury, expectedPublicationFeeBalanceAmmTreasury);
    }

    function testShouldNotTransferToTreasuryWhenCallerIsNotTreasuryTransferer() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        // when
        vm.expectRevert("IPOR_404");
        vm.prank(_userThree);
        _iporProtocol.joseph.transferToTreasury(100);
    }

    function testShouldNotTransferPublicationFeeToCharlieTreasuryWhenTreasuryManagerAddressIsIncorrect() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        vm.prank(_admin);
        _iporProtocol.joseph.setTreasuryManager(_userThree);

        // when
        vm.expectRevert("IPOR_405");
        vm.prank(_userThree);
        _iporProtocol.joseph.transferToTreasury(100);
    }

    function testShouldTransferTreasuryToTreasuryTreasurerWhenSimpleCase1() public {
        // given
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE4;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 transferredAmount = 100;
        uint256 expectedERC20BalanceTreasury = TestConstants.USER_SUPPLY_10MLN_18DEC + transferredAmount;
        uint256 expectedERC20BalanceAmmTreasury = TestConstants.USD_28_000_18DEC +
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC -
            transferredAmount;
        uint256 expectedTreasuryBalance = 114696891674244800;

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);

        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC
        );

        vm.startPrank(_admin);
        _iporProtocol.joseph.setTreasuryManager(_userThree);
        _iporProtocol.joseph.setTreasury(_userOne);
        vm.stopPrank();

        // when
        vm.prank(_userThree);
        _iporProtocol.joseph.transferToTreasury(transferredAmount);
        // then
        AmmStorageTypes.ExtendedBalancesMemory memory balance = _iporProtocol.ammStorage.getExtendedBalance();
        uint256 actualERC20BalanceTreasury = _iporProtocol.asset.balanceOf(_userOne);
        uint256 actualERC20BalanceAmmTreasury = _iporProtocol.asset.balanceOf(address(_iporProtocol.ammTreasury));

        assertEq(actualERC20BalanceTreasury, expectedERC20BalanceTreasury);
        assertEq(actualERC20BalanceAmmTreasury, expectedERC20BalanceAmmTreasury);
        assertEq(balance.treasury, expectedTreasuryBalance);
    }
}
