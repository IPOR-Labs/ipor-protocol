// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveDai.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenCompoundDai.sol";
import "../../contracts/mocks/MockStanleyStrategies.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/tokens/IporToken.sol";
import "../../contracts/mocks/TestnetFaucet.sol";
import "../../contracts/amm/spread/MiltonSpreadModelDai.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/vault/StanleyDai.sol";
import "../../contracts/amm/MiltonDai.sol";
import "../../contracts/amm/pool/JosephDai.sol";
import "../../contracts/facades/IporOracleFacadeDataProvider.sol";
import "./MockJosephDai.sol";

contract JosephOnlyRebalanceTest is Test, TestCommons {
    MockTestnetToken internal _dai;
    IpToken internal _ipDai;
    uint32 private _blockTimestamp = 1641701;

    function testShouldNotRebalanceWhenNotAppointedSender() public {
        // given
        Amm memory amm = _createAmmForDai();
        // when
        vm.expectRevert(bytes(JosephErrors.CALLER_NOT_APPOINTED_TO_REBALANCE));
        amm.joseph.rebalance();
    }

    function testShouldAddUserToAppointedRebalanceSender() public {
        // given
        address user = _getUserAddress(1);
        Amm memory amm = _createAmmForDai();
        bool isAppointedBefore = amm.joseph.isAppointedToRebalance(user);

        // when
        amm.joseph.addAppointedToRebalance(user);

        // then
        bool isAppointedAfter = amm.joseph.isAppointedToRebalance(user);
        assertFalse(isAppointedBefore);
        assertTrue(isAppointedAfter);
    }

    function testShouldRemoveUserFromAppointedRebalanceSender() public {
        // given
        address user = _getUserAddress(1);
        Amm memory amm = _createAmmForDai();
        amm.joseph.addAppointedToRebalance(user);
        bool isAppointedBefore = amm.joseph.isAppointedToRebalance(user);

        // when
        amm.joseph.removeAppointedToRebalance(user);

        // then
        bool isAppointedAfter = amm.joseph.isAppointedToRebalance(user);
        assertTrue(isAppointedBefore);
        assertFalse(isAppointedAfter);
    }

    function testShouldRebalanceWhenAppointedSender() public {
        // given
        Amm memory amm = _createAmmForDai();
        amm.joseph.addAppointedToRebalance(address(this));

        // when
        vm.expectRevert(bytes(JosephErrors.STANLEY_BALANCE_IS_EMPTY));
        amm.joseph.rebalance();
    }

    function testShouldSwitchImplementationOfJoseph() public {
        // given
        Amm memory amm = _createAmmForOldJoseph();
        uint256 josephVersionBefore = amm.joseph.getVersion();
        JosephDai newJosephImplementation = new JosephDai();

        // when
        amm.joseph.upgradeTo(address(newJosephImplementation));
        uint256 josephVersionAfter = amm.joseph.getVersion();

        // then
        assertEq(josephVersionBefore, 0);
        assertEq(josephVersionAfter, 3);
    }

    function testShouldSwitchImplementationOfJosephAndDontChangeValuesInStorage() public {
        // given
        address userOne = _getUserAddress(1);
        address userTwo = _getUserAddress(2);

        Amm memory amm = _createAmmForOldJoseph();
        amm.joseph.setTreasury(userOne);
        amm.joseph.setTreasuryManager(userOne);
        amm.joseph.setCharlieTreasury(userOne);
        amm.joseph.setCharlieTreasuryManager(userOne);

        uint256 josephVersionBefore = amm.joseph.getVersion();
        address assetBefore = amm.joseph.getAsset();
        address stanleyBefore = amm.joseph.getStanley();
        address miltonStorageBefore = amm.joseph.getMiltonStorage();
        address miltonBefore = amm.joseph.getMilton();
        address ipTokenBefore = amm.joseph.getIpToken();
        address treasuryBefore = amm.joseph.getTreasury();
        address treasuryManagerBefore = amm.joseph.getTreasuryManager();
        address charlieTreasuryBefore = amm.joseph.getCharlieTreasury();
        address charlieTreasuryManager = amm.joseph.getCharlieTreasuryManager();

        JosephDai newJosephImplementation = new JosephDai();

        // when
        amm.joseph.upgradeTo(address(newJosephImplementation));
        amm.joseph.setTreasury(userTwo);
        amm.joseph.setTreasuryManager(userTwo);
        amm.joseph.setCharlieTreasury(userTwo);
        amm.joseph.setCharlieTreasuryManager(userTwo);
        amm.joseph.addAppointedToRebalance(userTwo);

        // then

        assertEq(assetBefore, amm.joseph.getAsset());
        assertEq(stanleyBefore, amm.joseph.getStanley());
        assertEq(miltonStorageBefore, amm.joseph.getMiltonStorage());
        assertEq(miltonBefore, amm.joseph.getMilton());
        assertEq(ipTokenBefore, amm.joseph.getIpToken());
        assertEq(treasuryBefore, userOne);
        assertEq(amm.joseph.getTreasury(), userTwo);
        assertEq(treasuryManagerBefore, userOne);
        assertEq(amm.joseph.getTreasuryManager(), userTwo);
        assertEq(charlieTreasuryBefore, userOne);
        assertEq(amm.joseph.getCharlieTreasury(), userTwo);
        assertEq(charlieTreasuryManager, userOne);
        assertEq(amm.joseph.getCharlieTreasuryManager(), userTwo);
        assertTrue(amm.joseph.isAppointedToRebalance(userTwo));

        assertEq(josephVersionBefore, 0);
        assertEq(amm.joseph.getVersion(), 3);
    }

    function _createAmmForDai() internal returns (Amm memory) {
        Amm memory amm;
        amm.ammTokens.dai = new MockTestnetToken(
            "Mocked DAI",
            "DAI",
            100_000_000 * 1e18,
            uint8(18)
        );
        amm.ammTokens.ipDai = new IpToken(
            "Interest bearing DAI",
            "ipDAI",
            address(amm.ammTokens.dai)
        );
        amm.ammTokens.ivDai = new IvTokenDai(
            "Inverse interest bearing DAI",
            "ivDAI",
            address(amm.ammTokens.dai)
        );
        amm.ammTokens.iporToken = new IporToken("Ipor Token", "IPOR", address(this));

        amm.aaveStrategy = _createAaveStrategy(amm);
        amm.compoundStrategy = _createCompoundStrategy(amm);
        amm.miltonSpreadModel = new MiltonSpreadModelDai();
        amm.iporOracle = _createIporOracleDai(address(amm.ammTokens.dai));
        amm.miltonStorage = _createStorage();
        amm.stanley = _createStanley(amm);
        amm.milton = _createMilton(amm);
        amm.joseph = _createJoseph(amm);
        _setupAmm(amm);
        return amm;
    }

    function _createAmmForOldJoseph() internal returns (Amm memory) {
        Amm memory amm;
        amm.ammTokens.dai = new MockTestnetToken(
            "Mocked DAI",
            "DAI",
            100_000_000 * 1e18,
            uint8(18)
        );
        amm.ammTokens.ipDai = new IpToken(
            "Interest bearing DAI",
            "ipDAI",
            address(amm.ammTokens.dai)
        );
        amm.ammTokens.ivDai = new IvTokenDai(
            "Inverse interest bearing DAI",
            "ivDAI",
            address(amm.ammTokens.dai)
        );
        amm.ammTokens.iporToken = new IporToken("Ipor Token", "IPOR", address(this));

        amm.aaveStrategy = _createAaveStrategy(amm);
        amm.compoundStrategy = _createCompoundStrategy(amm);
        amm.miltonSpreadModel = new MiltonSpreadModelDai();
        amm.iporOracle = _createIporOracleDai(address(amm.ammTokens.dai));
        amm.miltonStorage = _createStorage();
        amm.stanley = _createStanley(amm);
        amm.milton = _createMilton(amm);
        amm.joseph = _createMockJoseph(amm);
        _setupAmm(amm);
        return amm;
    }

    function _setupAmm(Amm memory amm) internal {
        amm.ammTokens.ipDai.setJoseph(address(amm.joseph));
        amm.ammTokens.ivDai.setStanley(address(amm.stanley));

        amm.milton.setJoseph(address(amm.joseph));
        amm.milton.setupMaxAllowanceForAsset(address(amm.joseph));
        amm.milton.setupMaxAllowanceForAsset(address(amm.stanley));

        amm.miltonStorage.setJoseph(address(amm.joseph));
        amm.miltonStorage.setMilton(address(amm.milton));

        amm.stanley.setMilton(address(amm.milton));
        amm.iporOracle.addUpdater(address(this));
        amm.aaveStrategy.setStanley(address(amm.stanley));
        amm.compoundStrategy.setStanley(address(amm.stanley));
    }

    function _createJoseph(Amm memory amm) internal returns (Joseph) {
        JosephDai josephImplementation = new JosephDai();
        return
            Joseph(
                address(
                    new ERC1967Proxy(
                        address(josephImplementation),
                        abi.encodeWithSignature(
                            "initialize(bool,address,address,address,address,address)",
                            false,
                            address(amm.ammTokens.dai),
                            address(amm.ammTokens.ivDai),
                            address(amm.milton),
                            address(amm.miltonStorage),
                            address(amm.stanley)
                        )
                    )
                )
            );
    }

    function _createMockJoseph(Amm memory amm) internal returns (Joseph) {
        MockJosephDai josephImplementation = new MockJosephDai();
        return
            Joseph(
                address(
                    new ERC1967Proxy(
                        address(josephImplementation),
                        abi.encodeWithSignature(
                            "initialize(bool,address,address,address,address,address)",
                            false,
                            address(amm.ammTokens.dai),
                            address(amm.ammTokens.ivDai),
                            address(amm.milton),
                            address(amm.miltonStorage),
                            address(amm.stanley)
                        )
                    )
                )
            );
    }

    function _createMilton(Amm memory amm) internal returns (Milton) {
        MiltonDai miltonImplementation = new MiltonDai();
        return
            Milton(
                address(
                    new ERC1967Proxy(
                        address(miltonImplementation),
                        abi.encodeWithSignature(
                            "initialize(bool,address,address,address,address,address)",
                            false,
                            address(amm.ammTokens.dai),
                            address(amm.iporOracle),
                            address(amm.miltonStorage),
                            address(amm.miltonSpreadModel),
                            address(amm.stanley)
                        )
                    )
                )
            );
    }

    function _createStanley(Amm memory amm) internal returns (Stanley) {
        StanleyDai stanleyImplementation = new StanleyDai();
        return
            Stanley(
                address(
                    new ERC1967Proxy(
                        address(stanleyImplementation),
                        abi.encodeWithSignature(
                            "initialize(address,address,address,address)",
                            address(amm.ammTokens.dai),
                            address(amm.ammTokens.ivDai),
                            address(amm.aaveStrategy),
                            address(amm.compoundStrategy)
                        )
                    )
                )
            );
    }

    function _createStorage() internal returns (MiltonStorage) {
        MiltonStorageDai miltonStorageImplementation = new MiltonStorageDai();
        return
            MiltonStorage(
                address(
                    new ERC1967Proxy(
                        address(miltonStorageImplementation),
                        abi.encodeWithSignature("initialize()")
                    )
                )
            );
    }

    function _createAaveStrategy(Amm memory amm) internal returns (MockTestnetStrategy) {
        MockTestnetShareTokenAaveDai mockTestnetShareTokenAaveDai = new MockTestnetShareTokenAaveDai(
                0
            );
        MockTestnetStrategyAaveDai mockTestnetStrategyAaveDaiImpl = new MockTestnetStrategyAaveDai();
        return
            MockTestnetStrategy(
                address(
                    new ERC1967Proxy(
                        address(mockTestnetStrategyAaveDaiImpl),
                        abi.encodeWithSignature(
                            "initialize(address,address)",
                            address(amm.ammTokens.dai),
                            address(mockTestnetShareTokenAaveDai)
                        )
                    )
                )
            );
    }

    function _createCompoundStrategy(Amm memory amm) internal returns (MockTestnetStrategy) {
        MockTestnetShareTokenCompoundDai mockTestnetShareTokenCompoundDai = new MockTestnetShareTokenCompoundDai(
                0
            );
        MockTestnetStrategyCompoundDai mockTestnetStrategyCompoundDaiImpl = new MockTestnetStrategyCompoundDai();
        return
            MockTestnetStrategy(
                address(
                    new ERC1967Proxy(
                        address(mockTestnetStrategyCompoundDaiImpl),
                        abi.encodeWithSignature(
                            "initialize(address,address)",
                            address(amm.ammTokens.dai),
                            address(mockTestnetShareTokenCompoundDai)
                        )
                    )
                )
            );
    }

    function _createIporOracleDai(address dai) internal returns (IporOracle) {
        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(dai);

        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(_blockTimestamp);

        uint64[] memory exponentialMovingAverages = new uint64[](1);
        exponentialMovingAverages[0] = uint64(3e16);

        uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);

        exponentialWeightedMovingVariances[0] = uint64(0);

        return
            IporOracle(
                address(
                    new ERC1967Proxy(
                        address(iporOracleImplementation),
                        abi.encodeWithSignature(
                            "initialize(address[],uint32[],uint64[],uint64[])",
                            assets,
                            updateTimestamps,
                            exponentialMovingAverages,
                            exponentialWeightedMovingVariances
                        )
                    )
                )
            );
    }

    struct AmmTokens {
        MockTestnetToken dai;
        IpToken ipDai;
        IvToken ivDai;
        IporToken iporToken;
    }

    struct Amm {
        AmmTokens ammTokens;
        MockTestnetStrategy aaveStrategy;
        MockTestnetStrategy compoundStrategy;
        IporOracle iporOracle;
        Stanley stanley;
        MiltonStorage miltonStorage;
        MiltonSpreadModel miltonSpreadModel;
        Milton milton;
        Joseph joseph;
    }
}
