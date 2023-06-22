// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@ipor-protocol/contracts/itf/ItfAssetManagement.sol";
import "@ipor-protocol/contracts/itf/ItfAssetManagement6D.sol";
import "@ipor-protocol/contracts/itf/ItfAssetManagement18D.sol";
import "@ipor-protocol/contracts/tokens/IvToken.sol";
import "@ipor-protocol/contracts/vault/strategies/StrategyAave.sol";
import "@ipor-protocol/contracts/vault/AssetManagementDai.sol";
import "@ipor-protocol/contracts/vault/AssetManagementUsdc.sol";
import "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";
import "@ipor-protocol/test/mocks/tokens/AAVEMockedToken.sol";
import "@ipor-protocol/test/mocks/assetManagement/MockCase2AssetManagement.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/aTokens/MockAUsdt.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/aTokens/MockAUsdc.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/aTokens/MockADai.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockADAI.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockADAI.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockLendingPoolAave.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockProviderAave.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockStakedAave.sol";
import "@ipor-protocol/test/mocks/assetManagement/aave/MockAaveIncentivesController.sol";
import "@ipor-protocol/test/mocks/assetManagement/compound/MockWhitePaper.sol";
import "@ipor-protocol/test/mocks/assetManagement/compound/MockCToken.sol";
import "@ipor-protocol/test/mocks/assetManagement/compound/MockComptroller.sol";
import "@ipor-protocol/test/mocks/assetManagement/MockTestnetStrategy.sol";

import "@ipor-protocol/test/mocks/tokens/MockedCOMPToken.sol";
import "@ipor-protocol/contracts/vault/strategies/StrategyCompound.sol";

contract AssetManagementUtils {
    function getTokenAUsdt() public returns (MockAUsdt) {
        return new MockAUsdt();
    }

    function getTokenAUsdc() public returns (MockAUsdc) {
        return new MockAUsdc();
    }

    function getTokenADai() public returns (MockADai) {
        return new MockADai();
    }

    function getMockADAI(address asset, address tokenOwner) public returns (MockADAI) {
        return new MockADAI(asset, tokenOwner);
    }

    function getTokenAave() public returns (AAVEMockedToken) {
        return new AAVEMockedToken(1000000000000000000000000000000, 18);
    }

    function getCToken(
        address asset,
        address interestRateModel,
        uint8 decimal,
        string memory name,
        string memory code
    ) public returns (MockCToken) {
        return new MockCToken(asset, interestRateModel, decimal, name, code);
    }

    function getTokenComp() public returns (MockedCOMPToken) {
        return new MockedCOMPToken(1000000000000000000000000000000, 18);
    }

    function getItfAssetManagementUsdt(address asset) public returns (ItfAssetManagement itfAssetManagement) {
        IvToken ivToken = new IvToken("IV USDT", "ivUSDT", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveUsdt(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundUsdt(asset);

        ItfAssetManagement6D itfAssetManagementImpl = new ItfAssetManagement6D();

        address itfAssetManagementProxyAddress = address(
            new ERC1967Proxy(
                address(itfAssetManagementImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    asset,
                    ivToken,
                    address(strategyAave),
                    address(strategyCompound)
                )
            )
        );

        ivToken.setAssetManagement(itfAssetManagementProxyAddress);
        strategyAave.setAssetManagement(itfAssetManagementProxyAddress);
        strategyCompound.setAssetManagement(itfAssetManagementProxyAddress);

        return ItfAssetManagement(itfAssetManagementProxyAddress);
    }

    function getItfAssetManagementDai(address asset) public returns (ItfAssetManagement itfAssetManagement) {
        IvToken ivToken = new IvToken("IV DAI", "ivDAI", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveDai(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundDai(asset);

        ItfAssetManagement18D itfAssetManagementImpl = new ItfAssetManagement18D();

        address itfAssetManagementProxyAddress = address(
            new ERC1967Proxy(
                address(itfAssetManagementImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    asset,
                    ivToken,
                    address(strategyAave),
                    address(strategyCompound)
                )
            )
        );

        ivToken.setAssetManagement(itfAssetManagementProxyAddress);
        strategyAave.setAssetManagement(itfAssetManagementProxyAddress);
        strategyCompound.setAssetManagement(itfAssetManagementProxyAddress);

        return ItfAssetManagement(itfAssetManagementProxyAddress);
    }

    function getItfAssetManagementDai(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public returns (ItfAssetManagement18D) {
        ItfAssetManagement18D itfAssetManagementImpl = new ItfAssetManagement18D();
        address itfAssetManagementProxyAddress = address(
            new ERC1967Proxy(
                address(itfAssetManagementImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    asset,
                    ivToken,
                    strategyAave,
                    strategyCompound
                )
            )
        );
        return ItfAssetManagement18D(itfAssetManagementProxyAddress);
    }

    function getMockTestnetStrategyAaveUsdt(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategy strategyImpl = new MockTestnetStrategy();
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aUSDT", "aUSDT", 0, 6);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyCompoundUsdt(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategy strategyImpl = new MockTestnetStrategy();
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cUSDT", "cUSDT", 0, 6);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyAaveDai(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategy strategyImpl = new MockTestnetStrategy();
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share aDAI", "aDAI", 0, 18);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetShareTokenAaveUsdc(uint256 totalSupply) public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked Share aUSDC", "aUSDC", totalSupply, 6);
    }

    function getMockTestnetShareTokenCompoundUsdc(uint256 totalSupply) public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked Share cUSDC", "cUSDC", totalSupply, 6);
    }

    function getMockTestnetShareTokenAaveDai(uint256 totalSupply) public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked Share aDAI", "aDAI", totalSupply, 18);
    }

    function getMockTestnetShareTokenCompoundDai(uint256 totalSupply) public returns (MockTestnetToken) {
        return new MockTestnetToken("Mocked Share cDAI", "cDAI", totalSupply, 18);
    }

    function getMockTestnetStrategyCompoundDai(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategy strategyImpl = new MockTestnetStrategy();
        MockTestnetToken shareToken = new MockTestnetToken("Mocked Share cDAI", "cDAI", 0, 18);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockCase0AssetManagement(address asset) public returns (MockCaseBaseAssetManagement) {
        MockCaseBaseAssetManagement assetManagement = new MockCaseBaseAssetManagement();
        assetManagement.setAsset(asset);
        return assetManagement;
    }

    function getMockCaseBaseAssetManagement(address asset) public returns (MockCaseBaseAssetManagement) {
        MockCaseBaseAssetManagement assetManagement = new MockCaseBaseAssetManagement();
        assetManagement.setAsset(asset);
        return assetManagement;
    }

    function _getMockCase0AssetManagements(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    )
        internal
        returns (
            MockCaseBaseAssetManagement,
            MockCaseBaseAssetManagement,
            MockCaseBaseAssetManagement
        )
    {
        MockCaseBaseAssetManagement mockAssetManagementUsdt = new MockCaseBaseAssetManagement();
        mockAssetManagementUsdt.setAsset(tokenUsdt);
        MockCaseBaseAssetManagement mockAssetManagementUsdc = new MockCaseBaseAssetManagement();
        mockAssetManagementUsdc.setAsset(tokenUsdc);
        MockCaseBaseAssetManagement mockAssetManagementDai = new MockCaseBaseAssetManagement();
        mockAssetManagementDai.setAsset(tokenDai);
        return (mockAssetManagementUsdt, mockAssetManagementUsdc, mockAssetManagementDai);
    }

    function getMockCase1AssetManagement(address asset) public returns (MockCaseBaseAssetManagement) {
        MockCaseBaseAssetManagement assetManagement = new MockCaseBaseAssetManagement();
        assetManagement.setAsset(asset);
        return assetManagement;
    }

    function _getMockCase1AssetManagements(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    )
        internal
        returns (
            MockCaseBaseAssetManagement,
            MockCaseBaseAssetManagement,
            MockCaseBaseAssetManagement
        )
    {
        MockCaseBaseAssetManagement mockAssetManagementUsdt = new MockCaseBaseAssetManagement();
        mockAssetManagementUsdt.setAsset(tokenUsdt);
        MockCaseBaseAssetManagement mockAssetManagementUsdc = new MockCaseBaseAssetManagement();
        mockAssetManagementUsdc.setAsset(tokenUsdc);
        MockCaseBaseAssetManagement mockAssetManagementDai = new MockCaseBaseAssetManagement();
        mockAssetManagementDai.setAsset(tokenDai);
        return (mockAssetManagementUsdt, mockAssetManagementUsdc, mockAssetManagementDai);
    }

    function getMockCase2AssetManagement(address asset) public returns (MockCase2AssetManagement) {
        MockCase2AssetManagement assetManagement = new MockCase2AssetManagement();
        assetManagement.setAsset(asset);
        return assetManagement;
    }

    function getMockLendingPoolAave(
        address dai,
        address aDai,
        uint256 liquidityRatesDai,
        address usdc,
        address aUsdc,
        uint256 liquidityRatesUsdc,
        address usdt,
        address aUsdt,
        uint256 liquidityRatesUsdt
    ) public returns (MockLendingPoolAave) {
        return
            new MockLendingPoolAave(
                dai,
                aDai,
                liquidityRatesDai,
                usdc,
                aUsdc,
                liquidityRatesUsdc,
                usdt,
                aUsdt,
                liquidityRatesUsdt
            );
    }

    function getMockProviderAave(address lendingPoolAddress) public returns (MockProviderAave) {
        return new MockProviderAave(lendingPoolAddress);
    }

    function getMockStakedAave(address aaveTokenAddress) public returns (MockStakedAave) {
        return new MockStakedAave(aaveTokenAddress);
    }

    function getMockAaveIncentivesController(address stakedAaveAddress) public returns (MockAaveIncentivesController) {
        return new MockAaveIncentivesController(stakedAaveAddress);
    }

    function getStrategyAave(
        address tokenAddress,
        address aTokenAddress,
        address addressProviderAddress,
        address stakedAaveAddress,
        address aaveIncentivesControllerAddress,
        address aaveTokenAddress
    ) public returns (StrategyAave) {
        StrategyAave strategyImpl = new StrategyAave();
        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address)",
                tokenAddress,
                aTokenAddress,
                addressProviderAddress,
                stakedAaveAddress,
                aaveIncentivesControllerAddress,
                aaveTokenAddress
            )
        );
        return StrategyAave(address(strategyProxy));
    }

    function getMockWhitePaper() public returns (MockWhitePaper) {
        return new MockWhitePaper();
    }

    function getMockComptroller(
        address tokenCOMP,
        address cUSDT,
        address cUSDC,
        address cDAI
    ) public returns (MockComptroller) {
        return new MockComptroller(tokenCOMP, cUSDT, cUSDC, cDAI);
    }

    function getStrategyCompound(
        address asset,
        address shareToken,
        address comptroller,
        address tokenComp
    ) public returns (StrategyCompound) {
        StrategyCompound strategyCompoundImpl = new StrategyCompound();
        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyCompoundImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                asset,
                shareToken,
                comptroller,
                tokenComp
            )
        );
        return StrategyCompound(address(strategyProxy));
    }

    function getAssetManagementDai(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public returns (AssetManagementDai) {
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(asset),
                address(ivToken),
                address(strategyAave),
                address(strategyCompound)
            )
        );
        return AssetManagementDai(address(assetManagementDaiProxy));
    }

    function getAssetManagementUsdc(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public returns (AssetManagementUsdc) {
        AssetManagementUsdc assetManagementUsdcImpl = new AssetManagementUsdc();
        ERC1967Proxy assetManagementUsdcProxy = new ERC1967Proxy(
            address(assetManagementUsdcImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(asset),
                address(ivToken),
                address(strategyAave),
                address(strategyCompound)
            )
        );
        return AssetManagementUsdc(address(assetManagementUsdcProxy));
    }

    function getMockTestnetStrategy(address asset, address shareToken) public returns (MockTestnetStrategy) {
        MockTestnetStrategy strategyImpl = new MockTestnetStrategy();
        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, shareToken)
        );
        return MockTestnetStrategy(address(strategyProxy));
    }
}
