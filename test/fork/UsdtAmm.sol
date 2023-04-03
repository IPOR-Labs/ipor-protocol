// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../../contracts/vault/StanleyUsdt.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/amm/pool/Joseph.sol";
import "../../contracts/amm/pool/JosephUsdt.sol";
import "../../contracts/amm/Milton.sol";
import "../../contracts/amm/MiltonUsdt.sol";
import "../../contracts/amm/spread/MiltonSpreadModelUsdt.sol";
import "../../contracts/amm/spread/MiltonSpreadModel.sol";
import "../../contracts/mocks/stanley/MockStrategy.sol";
import "./IAsset.sol";

contract UsdtAmm is Test, TestCommons {
    address private constant _algorithmFacade = 0x9D4BD8CB9DA419A9cA1343A5340eD4Ce07E85140;
    address private constant _comptrollerAddress = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address private constant _compTokenAddress = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address private constant _addressProviderAave = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address private constant _stkAave = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address private constant _aaveIncentiveAddress = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    address private constant _aaveTokenAddress = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant cUsdt = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9;
    address public constant aUsdt = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

    address public ivUsdt;
    address public ipUsdt;

    IporOracle public iporOracle;

    Stanley public stanley;
    StrategyCompound public strategyCompound;
    StrategyCompound public strategyCompoundV2;
    StrategyAave public strategyAave;
    StrategyAave public strategyAaveV2;

    Joseph public joseph;
    Milton public milton;
    MiltonStorage public miltonStorage;
    MiltonSpreadModel public miltonSpreadModel;

    constructor(address owner) {
        vm.startPrank(owner);
        _createIpUsdt();
        _createIvUsdt();
        strategyCompound = _createCompoundStrategy();
        strategyCompoundV2 = _createCompoundStrategy();
        strategyAave = _createAaveStrategy();
        strategyAaveV2 = _createAaveStrategy();
        _createStanley();
        _createMiltonStorage();
        _createMiltonSpreadModel();
        _createIporOracle();
        _createMilton();
        _createJoseph();
        _setupJoseph(owner);
        _setupIpToken();
        _setupIvToken();
        _setupMilton();
        _setupMiltonStorage();
        _setupStanley();
        _setupStrategyAave();
        _setupStrategyCompound();
        _setupIporOracle(owner);
        vm.stopPrank();
    }

    function approveMiltonJoseph(address user) public {
        vm.startPrank(user);
        IAsset(usdt).approve(address(joseph), type(uint256).max);
        IAsset(usdt).approve(address(milton), type(uint256).max);
        vm.stopPrank();
    }

    function overrideAaveStrategyWithZeroApr(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setStanley(address(stanley));
        strategy.setBalance(0);
        strategy.setShareToken(aUsdt);
        strategy.setApr(0);
        strategy.setAsset(usdt);
        vm.prank(owner);
        stanley.setStrategyAave(address(strategy));
    }

    function restoreStrategies(address owner) public {
        vm.startPrank(owner);
        stanley.setStrategyAave(address(strategyAave));
        stanley.setStrategyCompound(address(strategyCompound));
        vm.stopPrank();
    }

    function overrideCompoundStrategyWithZeroApr(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setStanley(address(stanley));
        strategy.setBalance(0);
        strategy.setShareToken(cUsdt);
        strategy.setApr(0);
        strategy.setAsset(usdt);
        vm.prank(owner);
        stanley.setStrategyCompound(address(strategy));
    }

    function createCompoundStrategy() external returns (StrategyCompound) {
        StrategyCompound strategy = _createCompoundStrategy();
        strategy.setStanley(address(stanley));
        return strategy;
    }

    function createAaveStrategy() external returns (StrategyAave) {
        StrategyAave strategy = _createAaveStrategy();
        strategy.setStanley(address(stanley));
        return strategy;
    }

    function _createIpUsdt() internal {
        ipUsdt = address(new IpToken("IP USDT", "ipUSDT", usdt));
    }

    function _createIvUsdt() internal {
        ivUsdt = address(new IvToken("IV USDT", "ivUSDT", usdt));
    }

    function _createCompoundStrategy() internal returns (StrategyCompound) {
        StrategyCompound implementation = new StrategyCompound();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                usdt,
                cUsdt,
                _comptrollerAddress,
                _compTokenAddress
            )
        );
        return StrategyCompound(address(proxy));
    }

    function _createAaveStrategy() internal returns (StrategyAave) {
        StrategyAave implementation = new StrategyAave();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address)",
                usdt,
                aUsdt,
                _addressProviderAave,
                _stkAave,
                _aaveIncentiveAddress,
                _aaveTokenAddress
            )
        );
        return StrategyAave(address(proxy));
    }

    function _createStanley() internal {
        StanleyUsdt implementation = new StanleyUsdt();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                usdt,
                ivUsdt,
                address(strategyAave),
                address(strategyCompound)
            )
        );

        stanley = Stanley(address(proxy));
    }

    function _createMiltonStorage() internal {
        MiltonStorageUsdt implementation = new MiltonStorageUsdt();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        miltonStorage = MiltonStorage(address(proxy));
    }

    function _createMiltonSpreadModel() internal {
        miltonSpreadModel = new MiltonSpreadModelUsdt();
    }

    function _createIporOracle() internal {
        IporOracle iporOracleImplementation = new IporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(usdt);

        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(1640000000);

        uint64[] memory exponentialMovingAverages = new uint64[](1);
        exponentialMovingAverages[0] = uint64(32706669664256327);

        uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);

        exponentialWeightedMovingVariances[0] = uint64(49811986068491);

        iporOracle = IporOracle(
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

    function _createMilton() internal {
        MiltonUsdt implementation = new MiltonUsdt();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                usdt,
                address(iporOracle),
                address(miltonStorage),
                address(miltonSpreadModel),
                address(stanley)
            )
        );
        milton = Milton(address(proxy));
    }

    function _createJoseph() internal {
        JosephUsdt implementation = new JosephUsdt();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                usdt,
                ipUsdt,
                address(milton),
                address(miltonStorage),
                address(stanley)
            )
        );
        joseph = Joseph(address(proxy));
    }

    function _setupJoseph(address owner) internal {
        joseph.addAppointedToRebalance(owner);
    }

    function _setupMilton() internal {
        milton.setJoseph(address(joseph));
        milton.setupMaxAllowanceForAsset(address(joseph));
        milton.setupMaxAllowanceForAsset(address(stanley));
    }

    function _setupIpToken() internal {
        IpToken(ipUsdt).setJoseph(address(joseph));
    }

    function _setupMiltonStorage() internal {
        miltonStorage.setJoseph(address(joseph));
        miltonStorage.setMilton(address(milton));
    }

    function _setupStanley() internal {
        stanley.setMilton(address(milton));
    }

    function _setupIvToken() internal {
        IvToken(ivUsdt).setStanley(address(stanley));
    }

    function _setupStrategyAave() internal {
        strategyAave.setStanley(address(stanley));
        strategyAaveV2.setStanley(address(stanley));
    }

    function _setupStrategyCompound() internal {
        strategyCompound.setStanley(address(stanley));
        strategyCompoundV2.setStanley(address(stanley));
    }

    function _setupIporOracle(address owner) internal {
        iporOracle.setIporAlgorithmFacade(_algorithmFacade);
        iporOracle.addUpdater(owner);
        iporOracle.updateIndex(usdt);
    }
}
