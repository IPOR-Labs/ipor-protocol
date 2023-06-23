// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/interfaces/IAmmTreasuryFacadeDataProvider.sol";
import "contracts/interfaces/IAmmStorage.sol";
import "contracts/interfaces/IAmmTreasury.sol";
import "contracts/facades/AmmTreasuryFacadeDataProvider.sol";
import "test/mocks/ammTreasury/MockAmmTreasury.sol";
import "test/mocks/spread/MockSpreadModel.sol";
import "test/mocks/ammTreasury/MockAmmTreasury.sol";

contract AmmTreasuryUtils is Test {
    struct ExpectedAmmTreasuryBalances {
        uint256 expectedPayoffAbs;
        uint256 expectedAmmTreasuryBalance;
        int256 expectedOpenerUserBalance;
        int256 expectedCloserUserBalance;
        uint256 expectedLiquidityPoolBalance;
        uint256 expectedSumOfBalancesBeforePayout;
        uint256 expectedAdminBalance;
    }

    function prepareMockSpreadModel(
        uint256 calculateQuotePayFixedValue,
        uint256 calculateQuoteReceiveFixedValue,
        int256 calculateSpreadPayFixedValue,
        int256 calculateSpreadReceiveFixedVaule
    ) public returns (MockSpreadModel) {
        MockSpreadModel ammTreasurySpreadModel = new MockSpreadModel(
            calculateQuotePayFixedValue,
            calculateQuoteReceiveFixedValue,
            calculateSpreadPayFixedValue,
            calculateSpreadReceiveFixedVaule
        );
        return ammTreasurySpreadModel;
    }

    function getAmmTreasuryFacadeDataProvider(
        address iporOracle,
        address[] memory assets,
        address[] memory ammTreasurys,
        address[] memory ammStorages,
        address[] memory josephs
    ) public returns (IAmmTreasuryFacadeDataProvider) {
        AmmTreasuryFacadeDataProvider ammTreasuryFacadeDataProviderImplementation = new AmmTreasuryFacadeDataProvider();
        ERC1967Proxy ammTreasuryFacadeDataProviderProxy = new ERC1967Proxy(
            address(ammTreasuryFacadeDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address,address[],address[],address[],address[])",
                iporOracle,
                assets,
                ammTreasurys,
                ammStorages,
                josephs
            )
        );
        return IAmmTreasuryFacadeDataProvider(address(ammTreasuryFacadeDataProviderProxy));
    }

    function prepareAmmTreasury(
        IAmmTreasury ammTreasury,
        address joseph,
        address assetManagement
    ) public {
        IAmmStorage ammStorage = IAmmStorage(ammTreasury.getAmmStorage());
        ammStorage.setJoseph(joseph);
        ammStorage.setAmmTreasury(address(ammTreasury));
        ammTreasury.setJoseph(joseph);
        ammTreasury.setupMaxAllowanceForAsset(joseph);
        ammTreasury.setupMaxAllowanceForAsset(assetManagement);
    }

    function getMockCase0AmmTreasuryUsdc(
        address tokenUsdc,
        address iporOracle,
        address ammStorageUsdc,
        address ammTreasurySpreadModel,
        address assetManagementUsdc,
        address iporRiskManagementOracle
    ) public returns (MockAmmTreasury) {
        MockAmmTreasury mockCase0AmmTreasuryUsdcImplementation = new MockAmmTreasury(
            iporRiskManagementOracle,
            MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
            6
        );
        ERC1967Proxy ammTreasuryUsdcProxy = new ERC1967Proxy(
            address(mockCase0AmmTreasuryUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdc,
                iporOracle,
                ammStorageUsdc,
                ammTreasurySpreadModel,
                assetManagementUsdc
            )
        );
        return MockAmmTreasury(address(ammTreasuryUsdcProxy));
    }

    function getMockCase0AmmTreasuryDai(
        address tokenDai,
        address iporOracle,
        address ammStorageDai,
        address ammTreasurySpreadModel,
        address assetManagementDai,
        address iporRiskManagementOracle
    ) public returns (MockAmmTreasury) {
        MockAmmTreasury mockCase0AmmTreasuryDaiImplementation = new MockAmmTreasury(
            iporRiskManagementOracle,
            MockAmmTreasury.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
            18
        );
        ERC1967Proxy ammTreasuryDaiProxy = new ERC1967Proxy(
            address(mockCase0AmmTreasuryDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenDai,
                iporOracle,
                ammStorageDai,
                ammTreasurySpreadModel,
                assetManagementDai
            )
        );
        return MockAmmTreasury(address(ammTreasuryDaiProxy));
    }
}
