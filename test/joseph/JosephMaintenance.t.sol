// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/amm/pool/JosephDai.sol";
import "contracts/amm/pool/JosephUsdt.sol";
import "contracts/amm/pool/JosephUsdc.sol";

contract JosephMaintenance is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

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
    }

    function testShouldPauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.joseph.pause();

        // then
        vm.prank(_userOne);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.provideLiquidity(123);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.joseph.addAppointedToRebalance(_admin);

        // when
        vm.startPrank(_admin);
        _iporProtocol.joseph.pause();

        // then
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.rebalance();
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.depositToStanley(123);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.withdrawFromStanley(123);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.withdrawAllFromStanley();
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.setCharlieTreasury(_userTwo);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.setTreasury(_userTwo);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.setCharlieTreasuryManager(_userTwo);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.setTreasuryManager(_userTwo);
        vm.stopPrank();
        vm.startPrank(_userOne);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.provideLiquidity(123);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.redeem(123);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.transferToTreasury(123);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.transferToCharlieTreasury(123);
        vm.stopPrank();
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);

        // when
        vm.prank(_admin);
        _iporProtocol.joseph.pause();

        // then
        vm.startPrank(_userOne);
        _iporProtocol.joseph.getVersion();
        _iporProtocol.joseph.getCharlieTreasury();
        _iporProtocol.joseph.getTreasury();
        _iporProtocol.joseph.getCharlieTreasuryManager();
        _iporProtocol.joseph.getTreasuryManager();
        _iporProtocol.joseph.getRedeemLpMaxUtilizationRate();
        _iporProtocol.joseph.getMiltonStanleyBalanceRatio();
        _iporProtocol.joseph.getAsset();
        _iporProtocol.joseph.calculateExchangeRate();
        vm.stopPrank();
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAdmin() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_userThree);
        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.joseph.pause();
    }

    function testShouldUnpauseSmartContractWhenSenderIsAdmin() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.joseph.pause();

        vm.prank(_userOne);
        vm.expectRevert("Pausable: paused");
        _iporProtocol.joseph.provideLiquidity(123);

        // when
        vm.prank(_admin);
        _iporProtocol.joseph.unpause();

        vm.prank(_userOne);
        _iporProtocol.joseph.provideLiquidity(123);

        // then
        assertEq(_iporProtocol.ipToken.balanceOf(_userOne), 123);
    }

    function testShouldNotUnPauseSmartContractWhenSenderIsNotAdmin() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.joseph.pause();

        // when
        vm.prank(_userThree);
        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.joseph.unpause();
    }

    function testShouldTransferOwnershipWhenSimpleCase1() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.joseph.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.joseph.confirmTransferOwnership();

        // then
        vm.prank(_userOne);
        assertEq(_iporProtocol.joseph.owner(), _userTwo);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_userThree);
        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.joseph.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderIsNotAppointedOwner() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.joseph.transferOwnership(_userTwo);

        // then
        vm.prank(_userThree);
        vm.expectRevert("IPOR_007");
        _iporProtocol.joseph.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderIsNotAppointedOwner() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        _iporProtocol.joseph.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.joseph.confirmTransferOwnership();

        // then
        vm.prank(_userTwo);
        vm.expectRevert("IPOR_007");
        _iporProtocol.joseph.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_admin);
        _iporProtocol.joseph.transferOwnership(_userTwo);
        vm.prank(_userTwo);
        _iporProtocol.joseph.confirmTransferOwnership();

        // when
        vm.prank(_admin);
        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.joseph.transferOwnership(_userTwo);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.startPrank(_admin);
        _iporProtocol.joseph.transferOwnership(_userTwo);

        // when
        _iporProtocol.joseph.transferOwnership(_userTwo);
        vm.stopPrank();

        // then
        vm.prank(_userOne);
        assertEq(_iporProtocol.joseph.owner(), _admin);
    }

    function testShouldNotSendETHToJosephDAI() public payable {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.joseph).call{value: msg.value}("");
    }

    function testShouldNotSendETHToJosephUSDC() public payable {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.joseph).call{value: msg.value}("");
    }

    function testShouldNotSendETHToJosephUSDT() public payable {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(_iporProtocol.joseph).call{value: msg.value}("");
    }

    function testShouldDeployJosephDai() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        JosephDai josephDaiImplementation = new JosephDai();
        ERC1967Proxy josephDaiProxy = new ERC1967Proxy(
            address(josephDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(_iporProtocol.asset),
                address(_iporProtocol.ipToken),
                address(_iporProtocol.milton),
                address(_iporProtocol.miltonStorage),
                address(_iporProtocol.stanley)
            )
        );

        JosephDai josephDai = JosephDai(address(josephDaiProxy));

        // when
        address josephDaiAddress = josephDai.getAsset();

        // then
        assertEq(josephDaiAddress, address(_iporProtocol.asset));
    }

    function testShouldDeployJosephUsdc() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        JosephUsdc josephUsdcImplementation = new JosephUsdc();
        ERC1967Proxy josephUsdcProxy = new ERC1967Proxy(
            address(josephUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(_iporProtocol.asset),
                address(_iporProtocol.ipToken),
                address(_iporProtocol.milton),
                address(_iporProtocol.miltonStorage),
                address(_iporProtocol.stanley)
            )
        );

        JosephUsdc josephUsdc = JosephUsdc(address(josephUsdcProxy));

        // when
        address josephUsdcAddress = josephUsdc.getAsset();

        // then
        assertEq(josephUsdcAddress, address(_iporProtocol.asset));
    }

    function testShouldDeployJosephUsdt() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        JosephUsdt josephUsdtImplementation = new JosephUsdt();
        ERC1967Proxy josephUsdtProxy = new ERC1967Proxy(
            address(josephUsdtImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(_iporProtocol.asset),
                address(_iporProtocol.ipToken),
                address(_iporProtocol.milton),
                address(_iporProtocol.miltonStorage),
                address(_iporProtocol.stanley)
            )
        );

        JosephUsdt josephUsdt = JosephUsdt(address(josephUsdtProxy));

        // when
        address josephUsdtAddress = josephUsdt.getAsset();

        // then
        assertEq(josephUsdtAddress, address(_iporProtocol.asset));
    }

    function testShouldReturnDefaultMiltonStanleyBalanceRatio() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        uint256 ratio = _iporProtocol.joseph.getMiltonStanleyBalanceRatio();

        // then
        assertEq(ratio, 85 * TestConstants.D16);
    }

    function testShouldChangeMiltonStanleyBalanceRatio() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.startPrank(_admin);
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(TestConstants.PERCENTAGE_50_18DEC);

        // then
        vm.stopPrank();
        uint256 ratio = _iporProtocol.joseph.getMiltonStanleyBalanceRatio();
        assertEq(ratio, TestConstants.PERCENTAGE_50_18DEC);
    }

    function testShouldNotChangeMiltonStanleyBalanceRatioWhenNewRatioIsZero() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        vm.expectRevert("IPOR_409");
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(TestConstants.ZERO);
    }

    function testShouldNotChangeMiltonStanleyBalanceRatioWhenNewRatioIsGreaterThanOne() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_admin);
        vm.expectRevert("IPOR_409");
        _iporProtocol.joseph.setMiltonStanleyBalanceRatio(TestConstants.D18);
    }
}
