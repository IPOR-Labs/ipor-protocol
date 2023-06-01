// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/tokens/IvToken.sol";
import "contracts/oracles/IporOracle.sol";
import "contracts/vault/AssetManagementDai.sol";
import "contracts/vault/strategies/StrategyCompound.sol";
import "contracts/vault/strategies/StrategyAave.sol";
import "contracts/amm/pool/Joseph.sol";
import "contracts/amm/pool/JosephDai.sol";
import "contracts/amm/AmmTreasury.sol";
import "contracts/amm/AmmTreasuryDai.sol";
import "contracts/amm/spread/AmmTreasurySpreadModelDai.sol";
import "contracts/amm/spread/AmmTreasurySpreadModel.sol";
import "contracts/mocks/assetManagement/MockStrategy.sol";
import "contracts/vault/interfaces/aave/IAaveIncentivesController.sol";
import "../utils/IporRiskManagementOracleUtils.sol";
import "../utils/TestConstants.sol";

contract DaiAmm is Test, TestCommons, IporRiskManagementOracleUtils {
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
    IIporRiskManagementOracle public iporRiskManagementOracle;

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
        _createIpDai();
        _createIvDai();
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

    function overrideAaveStrategyWithZeroApr(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setAssetManagement(address(assetManagement));
        strategy.setBalance(0);
        strategy.setShareToken(aDai);
        strategy.setApr(0);
        strategy.setAsset(dai);
        vm.prank(owner);
        assetManagement.setStrategyAave(address(strategy));
    }

    function restoreStrategies(address owner) public {
        vm.startPrank(owner);
        assetManagement.setStrategyAave(address(strategyAave));
        assetManagement.setStrategyCompound(address(strategyCompound));
        vm.stopPrank();
    }

    function overrideCompoundStrategyWithZeroApr(address owner) public {
        MockStrategy strategy = new MockStrategy();
        strategy.setAssetManagement(address(assetManagement));
        strategy.setBalance(0);
        strategy.setShareToken(cDai);
        strategy.setApr(0);
        strategy.setAsset(dai);
        vm.prank(owner);
        assetManagement.setStrategyCompound(address(strategy));
    }

    function approveAmmTreasuryJoseph(address user) public {
        vm.startPrank(user);
        ERC20(dai).approve(address(joseph), type(uint256).max);
        ERC20(dai).approve(address(ammTreasury), type(uint256).max);
        vm.stopPrank();
    }

    function createAaveStrategy() external returns (StrategyAave) {
        StrategyAave strategy = _createAaveStrategy();
        strategy.setAssetManagement(address(assetManagement));
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

    function _createAssetManagement() internal {
        AssetManagementDai implementation = new AssetManagementDai();
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

        assetManagement = AssetManagement(address(proxy));
    }

    function _createAmmStorage() internal {
        AmmStorageDai implementation = new AmmStorageDai();
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), abi.encodeWithSignature("initialize()"));
        ammStorage = AmmStorage(address(proxy));
    }

    function _createAmmTreasurySpreadModel() internal {
        ammTreasurySpreadModel = new AmmTreasurySpreadModelDai();
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
                        "initialize(address[],uint32[])",
                        assets,
                        updateTimestamps,
                        exponentialMovingAverages,
                        exponentialWeightedMovingVariances
                    )
                )
            )
        );
    }

    function _createRiskManagementOracle() internal {
        iporRiskManagementOracle = getRiskManagementOracleAsset(
            address(this),
            address(dai),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_90_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
    }

    function _createAmmTreasury() internal {
        AmmTreasuryDai implementation = new AmmTreasuryDai(address(iporRiskManagementOracle));
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                dai,
                address(iporOracle),
                address(ammStorage),
                address(ammTreasurySpreadModel),
                address(assetManagement)
            )
        );
        ammTreasury = AmmTreasury(address(proxy));
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
        IpToken(ipDai).setJoseph(address(joseph));
    }

    function _setupAmmStorage() internal {
        ammStorage.setJoseph(address(joseph));
        ammStorage.setAmmTreasury(address(ammTreasury));
    }

    function _setupAssetManagement() internal {
        assetManagement.setAmmTreasury(address(ammTreasury));
    }

    function _setupIvToken() internal {
        IvToken(ivDai).setAssetManagement(address(assetManagement));
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
        iporOracle.updateIndex(dai);
    }
}
