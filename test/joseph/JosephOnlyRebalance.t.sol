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

contract JosephOnlyRebalanceTest is Test, TestCommons {
    MockTestnetToken internal _dai;
    IpToken internal _ipDai;
    uint32 private _blockTimestamp = 1641701;


    function setUp() public {
        Amm memory amm = _deployAmmForDai();
        console2.log("dai: ", address(amm.dai));
        console2.log("ipDai: ", address(amm.ipDai));
        console2.log("ivDai: ", address(amm.ivDai));
        console2.log("iporToken: ", address(amm.iporToken));
        console2.log("aaveStrategy: ", address(amm.aaveStrategy));
        console2.log("compoundStrategy: ", address(amm.compoundStrategy));
        console2.log("testnetFaucet: ", address(amm.testnetFaucet));
        console2.log("miltonSpreadModel: ", address(amm.miltonSpreadModel));
        console2.log("iporOracle: ", address(amm.iporOracle));


    }

    function testShouldBeOwnerOfContract() public {
        // given
        // when
        // then
        assertTrue(true);
    }

    function _deployAmmForDai() internal returns (Amm memory) {
        Amm memory amm;

        amm.dai = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        MockTestnetToken mockedUsdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        MockTestnetToken mockedUsdt = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));

        amm.ipDai = new IpToken("Interest bearing DAI", "ipDAI", address(amm.dai));
        amm.ivDai = new IvTokenDai("Inverse interest bearing DAI", "ivDAI", address(amm.dai));
        amm.iporToken = new IporToken("Ipor Token", "IPOR", address(this));

        MockTestnetShareTokenAaveDai mockTestnetShareTokenAaveDai = new MockTestnetShareTokenAaveDai(0);
        MockTestnetShareTokenCompoundDai mockTestnetShareTokenCompoundDai = new MockTestnetShareTokenCompoundDai(0);

        MockTestnetStrategyAaveDai mockTestnetStrategyAaveDaiImpl = new MockTestnetStrategyAaveDai();
        amm.aaveStrategy = new ERC1967Proxy(address(mockTestnetStrategyAaveDaiImpl), abi.encodeWithSignature("initialize(address,address)", address(amm.dai), address(mockTestnetShareTokenAaveDai)));

        MockTestnetStrategyCompoundDai mockTestnetStrategyCompoundDaiImpl = new MockTestnetStrategyCompoundDai();
        amm.compoundStrategy = new ERC1967Proxy(address(mockTestnetStrategyCompoundDaiImpl), abi.encodeWithSignature("initialize(address,address)", address(amm.dai), address(mockTestnetShareTokenCompoundDai)));

        TestnetFaucet testnetFaucetImplementation = new TestnetFaucet();
        amm.testnetFaucet = new ERC1967Proxy(address(testnetFaucetImplementation), abi.encodeWithSignature("initialize(address,address,address,address)", address(amm.dai), address(mockedUsdc), address(mockedUsdt), address(amm.iporToken)));

        amm.miltonSpreadModel = new MiltonSpreadModelDai();
        amm.iporOracle = _deployIporOracleDai(address(amm.dai));

        MiltonStorageDai miltonStorage = new MiltonStorageDai();


        return amm;
    }

    function _deployIporOracleDai(address dai) internal returns (ERC1967Proxy) {
        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(dai);


        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(_blockTimestamp);

        uint64[] memory exponentialMovingAverages = new uint64[](1);
        exponentialMovingAverages[0] = uint64(3e16);

        uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);

        exponentialWeightedMovingVariances[0] = uint64(0);

        return new ERC1967Proxy(
            address(iporOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint32[],uint64[],uint64[])",
                assets,
                updateTimestamps,
                exponentialMovingAverages,
                exponentialWeightedMovingVariances
            )
        );

    }

    struct Amm {
        MockTestnetToken dai;
        IpToken ipDai;
        IvTokenDai ivDai;
        IporToken iporToken;
        ERC1967Proxy aaveStrategy;
        ERC1967Proxy compoundStrategy;
        ERC1967Proxy testnetFaucet;
        ERC1967Proxy iporOracle;
        MiltonSpreadModelDai miltonSpreadModel;
        MiltonStorageDai miltonStorage;
    }
}