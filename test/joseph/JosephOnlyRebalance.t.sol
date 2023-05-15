// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/amm/pool/JosephDai.sol";
import "./MockJosephDai.sol";
import "../../contracts/itf/ItfJoseph18D.sol";

contract JosephOnlyRebalanceTest is Test, TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    MockTestnetToken internal _dai;
    IpToken internal _ipDai;
    uint32 private _blockTimestamp = 1641701;

    function setUp() public {
        _cfg.josephImplementation = address(new ItfJoseph18D());
        _cfg.iporRiskManagementOracleUpdater = address(this);
    }

    function testShouldNotRebalanceWhenNotAppointedSender() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.expectRevert(bytes(JosephErrors.CALLER_NOT_APPOINTED_TO_REBALANCE));
        _iporProtocol.joseph.rebalance();
    }

    function testShouldAddUserToAppointedRebalanceSender() public {
        // given
        address user = _getUserAddress(1);
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        bool isAppointedBefore = _iporProtocol.joseph.isAppointedToRebalance(user);

        // when
        _iporProtocol.joseph.addAppointedToRebalance(user);

        // then
        bool isAppointedAfter = _iporProtocol.joseph.isAppointedToRebalance(user);
        assertFalse(isAppointedBefore);
        assertTrue(isAppointedAfter);
    }

    function testShouldRemoveUserFromAppointedRebalanceSender() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        address user = _getUserAddress(1);

        _iporProtocol.joseph.addAppointedToRebalance(user);
        bool isAppointedBefore = _iporProtocol.joseph.isAppointedToRebalance(user);

        // when
        _iporProtocol.joseph.removeAppointedToRebalance(user);

        // then
        bool isAppointedAfter = _iporProtocol.joseph.isAppointedToRebalance(user);
        assertTrue(isAppointedBefore);
        assertFalse(isAppointedAfter);
    }

    function testShouldRebalanceWhenAppointedSender() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);
        _iporProtocol.joseph.addAppointedToRebalance(address(this));

        // when
        vm.expectRevert(bytes(JosephErrors.STANLEY_BALANCE_IS_EMPTY));
        _iporProtocol.joseph.rebalance();
    }

    function testShouldSwitchImplementationOfJoseph() public {
        // given
        _cfg.josephImplementation = address(new MockJosephDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 josephVersionBefore = _iporProtocol.joseph.getVersion();
        JosephDai newJosephImplementation = new JosephDai();

        // when
        _iporProtocol.joseph.upgradeTo(address(newJosephImplementation));
        uint256 josephVersionAfter = _iporProtocol.joseph.getVersion();

        // then
        assertEq(josephVersionBefore, 0);
        assertEq(josephVersionAfter, 3);
    }

    function testShouldSwitchImplementationOfJosephAndDontChangeValuesInStorage() public {
        // given
        _cfg.josephImplementation = address(new MockJosephDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        address userOne = _getUserAddress(1);
        address userTwo = _getUserAddress(2);

        _iporProtocol.joseph.setTreasury(userOne);
        _iporProtocol.joseph.setTreasuryManager(userOne);
        _iporProtocol.joseph.setCharlieTreasury(userOne);
        _iporProtocol.joseph.setCharlieTreasuryManager(userOne);

        uint256 josephVersionBefore = _iporProtocol.joseph.getVersion();
        address assetBefore = _iporProtocol.joseph.getAsset();
        address stanleyBefore = _iporProtocol.joseph.getStanley();
        address miltonStorageBefore = _iporProtocol.joseph.getMiltonStorage();
        address miltonBefore = _iporProtocol.joseph.getMilton();
        address ipTokenBefore = _iporProtocol.joseph.getIpToken();
        address treasuryBefore = _iporProtocol.joseph.getTreasury();
        address treasuryManagerBefore = _iporProtocol.joseph.getTreasuryManager();
        address charlieTreasuryBefore = _iporProtocol.joseph.getCharlieTreasury();
        address charlieTreasuryManager = _iporProtocol.joseph.getCharlieTreasuryManager();

        JosephDai newJosephImplementation = new JosephDai();

        // when
        _iporProtocol.joseph.upgradeTo(address(newJosephImplementation));
        _iporProtocol.joseph.setTreasury(userTwo);
        _iporProtocol.joseph.setTreasuryManager(userTwo);
        _iporProtocol.joseph.setCharlieTreasury(userTwo);
        _iporProtocol.joseph.setCharlieTreasuryManager(userTwo);
        _iporProtocol.joseph.addAppointedToRebalance(userTwo);

        // then

        assertEq(assetBefore, _iporProtocol.joseph.getAsset());
        assertEq(stanleyBefore, _iporProtocol.joseph.getStanley());
        assertEq(miltonStorageBefore, _iporProtocol.joseph.getMiltonStorage());
        assertEq(miltonBefore, _iporProtocol.joseph.getMilton());
        assertEq(ipTokenBefore, _iporProtocol.joseph.getIpToken());
        assertEq(treasuryBefore, userOne);
        assertEq(_iporProtocol.joseph.getTreasury(), userTwo);
        assertEq(treasuryManagerBefore, userOne);
        assertEq(_iporProtocol.joseph.getTreasuryManager(), userTwo);
        assertEq(charlieTreasuryBefore, userOne);
        assertEq(_iporProtocol.joseph.getCharlieTreasury(), userTwo);
        assertEq(charlieTreasuryManager, userOne);
        assertEq(_iporProtocol.joseph.getCharlieTreasuryManager(), userTwo);
        assertTrue(_iporProtocol.joseph.isAppointedToRebalance(userTwo));

        assertEq(josephVersionBefore, 0);
        assertEq(_iporProtocol.joseph.getVersion(), 3);
    }
}
