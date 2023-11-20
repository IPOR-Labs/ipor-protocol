// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "test/TestCommons.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/oracles/IporOracle.sol";
import "contracts/vault/AssetManagementUsdc.sol";
import "contracts/vault/strategies/StrategyCompound.sol";
import "contracts/vault/strategies/StrategyAave.sol";
import "contracts/amm/pool/Joseph.sol";
import "contracts/amm/pool/JosephUsdc.sol";
import "contracts/amm/AmmTreasury.sol";
import "contracts/amm/AmmTreasuryUsdc.sol";
import "contracts/amm/spread/AmmTreasurySpreadModelUsdc.sol";
import "contracts/amm/spread/AmmTreasurySpreadModel.sol";
import "test/mocks/assetManagement/MockStrategy.sol";
import "contracts/vault/interfaces/aave/IAaveIncentivesController.sol";
import "../utils/TestConstants.sol";

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

    AssetManagement public assetManagement;
    StrategyCompound public strategyCompound;
    StrategyCompound public strategyCompoundV2;
    StrategyAave public strategyAave;
    StrategyAave public strategyAaveV2;

    Joseph public joseph;
    AmmTreasury public ammTreasury;
    AmmStorage public ammStorage;
    AmmTreasurySpreadModel public ammTreasurySpreadModel;

    IAaveIncentivesController public aaveIncentivesController;

    constructor(address owner) {
        vm.startPrank(owner);
        _createIpUsdc();
        _createIvUsdc();
        strategyCompound = _createCompoundStrategy();
        strategyCompoundV2 = _createCompoundStrategy();
        strategyAave = _createAaveStrategy();
        strategyAaveV2 = _createAaveStrategy();
        _createAssetManagement();
        _createAmmStorage();
        _createAmmTreasurySpreadModel();
        _createIporOracle();
        _createRiskManagementOracle();
        _createAmmTreasury();
        _createJoseph();
        _createAaveIncentivesController();
        _setupJoseph(owner);
        _setupIpToken();
        _setupIvToken();
        _setupAmmTreasury();
        _setupAmmStorage();
        _setupAssetManagement();
        _setupStrategyAave();
        _setupStrategyCompound();
        _setupIporOracle(owner);
        vm.stopPrank();
    }

    function overrideAaveStrategyWithZeroApy(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setAssetManagement(address(assetManagement));
        strategy.setBalance(0);
        strategy.setShareToken(aUsdc);
        strategy.setApy(0);
        strategy.setAsset(usdc);
        vm.prank(owner);
        assetManagement.setStrategyAave(address(strategy));
    }

    function restoreStrategies(address owner) public {
        vm.startPrank(owner);
        assetManagement.setStrategyAave(address(strategyAave));
        assetManagement.setStrategyCompound(address(strategyCompound));
        vm.stopPrank();
    }

    function overrideCompoundStrategyWithZeroApy(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setAssetManagement(address(assetManagement));
        strategy.setBalance(0);
        strategy.setShareToken(cUsdc);
        strategy.setApy(0);
        strategy.setAsset(usdc);
        vm.prank(owner);
        assetManagement.setStrategyCompound(address(strategy));
    }

    function approveAmmTreasuryJoseph(address user) public {
        vm.startPrank(user);
        ERC20(usdc).approve(address(joseph), type(uint256).max);
        ERC20(usdc).approve(address(ammTreasury), type(uint256).max);
        vm.stopPrank();
    }

    function createAaveStrategy() external returns (StrategyAave) {
        StrategyAave strategy = _createAaveStrategy();
        strategy.setAssetManagement(address(assetManagement));
        return strategy;
    }

    function _createIpUsdc() internal {
        ipUsdc = address(new IpToken("IP USDC", "ipUSDC", usdc));
    }

    function _createIvUsdc() internal {
        ivUsdc = address(new IvToken("IV USDC", "ivUSDC", usdc));
    }

    function _createCompoundStrategy() internal returns (StrategyCompound) {
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
        return StrategyCompound(address(proxy));
    }

    function _createAaveStrategy() internal returns (StrategyAave) {
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
        return StrategyAave(address(proxy));
    }

    function _createAssetManagement() internal {
        AssetManagementUsdc implementation = new AssetManagementUsdc();
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

        assetManagement = AssetManagement(address(proxy));
    }

    function _createAmmStorage() internal {
        AmmStorageUsdc implementation = new AmmStorageUsdc();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), abi.encodeWithSignature("initialize()"));
        ammStorage = AmmStorage(address(proxy));
    }

    function _createAmmTreasurySpreadModel() internal {
        ammTreasurySpreadModel = new AmmTreasurySpreadModelUsdc();
    }

    function _createIporOracle() internal {
        IporOracle iporOracleImplementation = new IporOracle();
        address[] memory assets = new address[](1);
        assets[0] = address(usdc);

        uint32[] memory updateTimestamps = new uint32[](1);
        updateTimestamps[0] = uint32(1640000000);

        iporOracle = IporOracle(
            address(
                new ERC1967Proxy(
                    address(iporOracleImplementation),
                    abi.encodeWithSignature(
                        "initialize(address[],uint32[])",
                        assets,
                        updateTimestamps
                    )
                )
            )
        );
    }

    function _createRiskManagementOracle() internal {
        iporRiskManagementOracle = getRiskManagementOracleAsset(
            address(this),
            address(usdc),
            TestConstants.RMO_COLLATERAL_RATIO_48_PER,
            TestConstants.RMO_COLLATERAL_RATIO_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
    }

    function _createAmmTreasury() internal {
        AmmTreasuryUsdc implementation = new AmmTreasuryUsdc(address(iporRiskManagementOracle));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                usdc,
                address(iporOracle),
                address(ammStorage),
                address(ammTreasurySpreadModel),
                address(assetManagement)
            )
        );
        ammTreasury = AmmTreasury(address(proxy));
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
                address(ammTreasury),
                address(ammStorage),
                address(assetManagement)
            )
        );
        joseph = Joseph(address(proxy));
    }

    function _createAaveIncentivesController() internal {
        aaveIncentivesController = IAaveIncentivesController(_aaveIncentiveAddress);
    }

    function _setupJoseph(address owner) internal {
        joseph.addAppointedToRebalance(owner);
    }

    function _setupAmmTreasury() internal {
        ammTreasury.setJoseph(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(joseph));
        ammTreasury.setupMaxAllowanceForAsset(address(assetManagement));
    }

    function _setupIpToken() internal {
        IpToken(ipUsdc).setJoseph(address(joseph));
    }

    function _setupAmmStorage() internal {
        ammStorage.setJoseph(address(joseph));
        ammStorage.setAmmTreasury(address(ammTreasury));
    }

    function _setupAssetManagement() internal {
        assetManagement.setAmmTreasury(address(ammTreasury));
    }

    function _setupIvToken() internal {
        IvToken(ivUsdc).setAssetManagement(address(assetManagement));
    }

    function _setupStrategyAave() internal {
        strategyAave.setAssetManagement(address(assetManagement));
        strategyAaveV2.setAssetManagement(address(assetManagement));
    }

    function _setupStrategyCompound() internal {
        strategyCompound.setAssetManagement(address(assetManagement));
        strategyCompoundV2.setAssetManagement(address(assetManagement));
    }

    function _setupIporOracle(address owner) internal {
        iporOracle.setIporAlgorithmFacade(_algorithmFacade);
        iporOracle.addUpdater(owner);
        iporOracle.updateIndex(usdc);
    }
}
