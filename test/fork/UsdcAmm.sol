// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../../contracts/vault/StanleyUsdc.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/amm/pool/Joseph.sol";
import "../../contracts/amm/pool/JosephUsdc.sol";
import "../../contracts/amm/Milton.sol";
import "../../contracts/amm/MiltonUsdc.sol";
import "../../contracts/amm/spread/MiltonSpreadModelUsdc.sol";
import "../../contracts/amm/spread/MiltonSpreadModel.sol";

contract UsdcAmm is Test, TestCommons {
    address private constant _algorithmFacade = 0x9D4BD8CB9DA419A9cA1343A5340eD4Ce07E85140;
    address private constant _comptrollerAddress = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address private constant _compTokenAddress = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    address private constant _addressProviderAave = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    address private constant _stkAave = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address private constant _aaveIncentiveAddress = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    address private constant _aaveTokenAddress = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant cUsdc = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address public constant aUsdc = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

    address public ivUsdc;
    address public ipUsdc;

    IporOracle public iporOracle;

    Stanley public stanley;
    StrategyCompound public strategyCompound;
    StrategyAave public strategyAave;

    Joseph public joseph;
    Milton public milton;
    MiltonStorage public miltonStorage;
    MiltonSpreadModel public miltonSpreadModel;

    constructor(address owner) {
        vm.startPrank(owner);
        _createIpUsdc();
        _createIvUsdc();
        _createCompoundStrategy();
        _createAaveStrategy();
        _createStanley();
        _createMiltonStorage();
        _createMiltonSpreadModel();
        _createIporOracle();
        _createMilton();
        _createJoseph();
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
        ERC20(usdc).approve(address(joseph), type(uint256).max);
        ERC20(usdc).approve(address(milton), type(uint256).max);
        vm.stopPrank();
    }

    function _createIpUsdc() internal {
        ipUsdc = address(new IpToken("IP USDC", "ipUSDC", usdc));
    }

    function _createIvUsdc() internal {
        ivUsdc = address(new IvToken("IV USDC", "ivUSDC", usdc));
    }

    function _createCompoundStrategy() internal {
        StrategyCompound implementation = new StrategyCompound();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                usdc,
                cUsdc,
                _comptrollerAddress,
                _compTokenAddress
            )
        );
        strategyCompound = StrategyCompound(address(proxy));
    }

    function _createAaveStrategy() internal {
        StrategyAave implementation = new StrategyAave();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address)",
                usdc,
                aUsdc,
                _addressProviderAave,
                _stkAave,
                _aaveIncentiveAddress,
                _aaveTokenAddress
            )
        );
        strategyAave = StrategyAave(address(proxy));
    }

    function _createStanley() internal {
        StanleyUsdc implementation = new StanleyUsdc();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                usdc,
                ivUsdc,
                address(strategyAave),
                address(strategyCompound)
            )
        );

        stanley = Stanley(address(proxy));
    }

    function _createMiltonStorage() internal {
        MiltonStorageUsdc implementation = new MiltonStorageUsdc();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        miltonStorage = MiltonStorage(address(proxy));
    }

    function _createMiltonSpreadModel() internal {
        miltonSpreadModel = new MiltonSpreadModelUsdc();
    }

    function _createIporOracle() internal {
        IporOracle iporOracleImplementation = new IporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(usdc);

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
        MiltonUsdc implementation = new MiltonUsdc();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                usdc,
                address(iporOracle),
                address(miltonStorage),
                address(miltonSpreadModel),
                address(stanley)
            )
        );
        milton = Milton(address(proxy));
    }

    function _createJoseph() internal {
        JosephUsdc implementation = new JosephUsdc();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                usdc,
                ipUsdc,
                address(milton),
                address(miltonStorage),
                address(stanley)
            )
        );
        joseph = Joseph(address(proxy));
    }

    function _setupMilton() internal {
        milton.setJoseph(address(joseph));
        milton.setupMaxAllowanceForAsset(address(joseph));
        milton.setupMaxAllowanceForAsset(address(stanley));
    }

    function _setupIpToken() internal {
        IpToken(ipUsdc).setJoseph(address(joseph));
    }

    function _setupMiltonStorage() internal {
        miltonStorage.setJoseph(address(joseph));
        miltonStorage.setMilton(address(milton));
    }

    function _setupStanley() internal {
        stanley.setMilton(address(milton));
    }

    function _setupIvToken() internal {
        IvToken(ivUsdc).setStanley(address(stanley));
    }

    function _setupStrategyAave() internal {
        strategyAave.setStanley(address(stanley));
    }

    function _setupStrategyCompound() internal {
        strategyCompound.setStanley(address(stanley));
    }

    function _setupIporOracle(address owner) internal {
        iporOracle.setIporAlgorithmFacade(_algorithmFacade);
        iporOracle.addUpdater(owner);
        iporOracle.updateIndex(usdc);
    }
}
