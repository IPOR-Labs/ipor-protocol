// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../../contracts/vault/StanleyDai.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/amm/pool/Joseph.sol";
import "../../contracts/amm/pool/JosephDai.sol";
import "../../contracts/amm/Milton.sol";
import "../../contracts/amm/MiltonDai.sol";
import "../../contracts/amm/spread/MiltonSpreadModelDai.sol";
import "../../contracts/amm/spread/MiltonSpreadModel.sol";
import "../../contracts/mocks/stanley/MockStrategy.sol";

contract DaiAmm is Test, TestCommons {
    address private constant _algorithmFacade = 0x9D4BD8CB9DA419A9cA1343A5340eD4Ce07E85140;
    address private constant _comptrollerAddress = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address private constant _compTokenAddress = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address private constant _addressProviderAave = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address private constant _stkAave = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address private constant _aaveIncentiveAddress = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    address private constant _aaveTokenAddress = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant aDai = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

    address public ivDai;
    address public ipDai;

    IporOracle public iporOracle;

    Stanley public stanley;
    StrategyCompound public strategyCompound;
    StrategyAave public strategyAave;
    StrategyAave public strategyAaveV2;

    Joseph public joseph;
    Milton public milton;
    MiltonStorage public miltonStorage;
    MiltonSpreadModel public miltonSpreadModel;

    constructor(address owner) {
        vm.startPrank(owner);
        _createIpDai();
        _createIvDai();
        strategyCompound = _createCompoundStrategy();
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

    function overrideAaveStrategyWithZeroApr(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setStanley(address(stanley));
        strategy.setBalance(0);
        strategy.setShareToken(aDai);
        strategy.setApr(0);
        strategy.setAsset(dai);
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
        strategy.setShareToken(cDai);
        strategy.setApr(0);
        strategy.setAsset(dai);
        vm.prank(owner);
        stanley.setStrategyCompound(address(strategy));
    }

    function approveMiltonJoseph(address user) public {
        vm.startPrank(user);
        ERC20(dai).approve(address(joseph), type(uint256).max);
        ERC20(dai).approve(address(milton), type(uint256).max);
        vm.stopPrank();
    }

    function createAaveStrategy() external returns (StrategyAave) {
        StrategyAave strategy = _createAaveStrategy();
        strategy.setStanley(address(stanley));
        return strategy;
    }

    function _createIpDai() internal {
        ipDai = address(new IpToken("IP DAI", "ipDAI", dai));
    }

    function _createIvDai() internal {
        ivDai = address(new IvToken("IV DAI", "ivDAI", dai));
    }

    function _createCompoundStrategy() internal returns (StrategyCompound) {
        StrategyCompound implementation = new StrategyCompound();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                dai,
                cDai,
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
                dai,
                aDai,
                _addressProviderAave,
                _stkAave,
                _aaveIncentiveAddress,
                _aaveTokenAddress
            )
        );
        return StrategyAave(address(proxy));
    }

    function _createStanley() internal {
        StanleyDai implementation = new StanleyDai();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                dai,
                ivDai,
                address(strategyAave),
                address(strategyCompound)
            )
        );

        stanley = Stanley(address(proxy));
    }

    function _createMiltonStorage() internal {
        MiltonStorageDai implementation = new MiltonStorageDai();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        miltonStorage = MiltonStorage(address(proxy));
    }

    function _createMiltonSpreadModel() internal {
        miltonSpreadModel = new MiltonSpreadModelDai();
    }

    function _createIporOracle() internal {
        IporOracle iporOracleImplementation = new IporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(dai);

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
        MiltonDai implementation = new MiltonDai();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                dai,
                address(iporOracle),
                address(miltonStorage),
                address(miltonSpreadModel),
                address(stanley)
            )
        );
        milton = Milton(address(proxy));
    }

    function _createJoseph() internal {
        JosephDai implementation = new JosephDai();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                dai,
                ipDai,
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
        IpToken(ipDai).setJoseph(address(joseph));
    }

    function _setupMiltonStorage() internal {
        miltonStorage.setJoseph(address(joseph));
        miltonStorage.setMilton(address(milton));
    }

    function _setupStanley() internal {
        stanley.setMilton(address(milton));
    }

    function _setupIvToken() internal {
        IvToken(ivDai).setStanley(address(stanley));
    }

    function _setupStrategyAave() internal {
        strategyAave.setStanley(address(stanley));
        strategyAaveV2.setStanley(address(stanley));
    }

    function _setupStrategyCompound() internal {
        strategyCompound.setStanley(address(stanley));
    }

    function _setupIporOracle(address owner) internal {
        iporOracle.setIporAlgorithmFacade(_algorithmFacade);
        iporOracle.addUpdater(owner);
        iporOracle.updateIndex(dai);
    }
}
