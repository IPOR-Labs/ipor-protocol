// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/interfaces/IMiltonFacadeDataProvider.sol";
import "contracts/interfaces/IMiltonStorage.sol";
import "contracts/interfaces/IMiltonInternal.sol";
import "contracts/facades/MiltonFacadeDataProvider.sol";
import "contracts/mocks/milton/MockMilton.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/mocks/milton/MockMilton.sol";

contract MiltonUtils is Test {
    struct ExpectedMiltonBalances {
        uint256 expectedPayoffAbs;
        uint256 expectedMiltonBalance;
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
        MockSpreadModel miltonSpreadModel = new MockSpreadModel(
            calculateQuotePayFixedValue,
            calculateQuoteReceiveFixedValue,
            calculateSpreadPayFixedValue,
            calculateSpreadReceiveFixedVaule
        );
        return miltonSpreadModel;
    }

    function getMiltonFacadeDataProvider(
        address iporOracle,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs
    ) public returns (IMiltonFacadeDataProvider) {
        MiltonFacadeDataProvider miltonFacadeDataProviderImplementation = new MiltonFacadeDataProvider();
        ERC1967Proxy miltonFacadeDataProviderProxy = new ERC1967Proxy(
            address(miltonFacadeDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address,address[],address[],address[],address[])",
                iporOracle,
                assets,
                miltons,
                miltonStorages,
                josephs
            )
        );
        return IMiltonFacadeDataProvider(address(miltonFacadeDataProviderProxy));
    }

    function prepareMilton(
        IMiltonInternal milton,
        address joseph,
        address stanley
    ) public {
        IMiltonStorage miltonStorage = IMiltonStorage(milton.getMiltonStorage());
        miltonStorage.setJoseph(joseph);
        miltonStorage.setMilton(address(milton));
        milton.setJoseph(joseph);
        milton.setupMaxAllowanceForAsset(joseph);
        milton.setupMaxAllowanceForAsset(stanley);
    }

    function getMockCase0MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc,
        address iporRiskManagementOracle
    ) public returns (MockMilton) {
        MockMilton mockCase0MiltonUsdcImplementation = new MockMilton(
            iporRiskManagementOracle,
            MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
            6
        );
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(mockCase0MiltonUsdcImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdc,
                iporOracle,
                miltonStorageUsdc,
                miltonSpreadModel,
                stanleyUsdc
            )
        );
        return MockMilton(address(miltonUsdcProxy));
    }

    function getMockCase0MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai,
        address iporRiskManagementOracle
    ) public returns (MockMilton) {
        MockMilton mockCase0MiltonDaiImplementation = new MockMilton(
            iporRiskManagementOracle,
            MockMilton.InitParam(1e23, 3e14, 0, 10 * 1e18, 20, 10 * 1e18),
            18
        );
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(mockCase0MiltonDaiImplementation),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenDai,
                iporOracle,
                miltonStorageDai,
                miltonSpreadModel,
                stanleyDai
            )
        );
        return MockMilton(address(miltonDaiProxy));
    }
}
