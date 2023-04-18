// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/interfaces/IMiltonFacadeDataProvider.sol";
import "../../contracts/interfaces/IMiltonStorage.sol";
import "../../contracts/interfaces/IMiltonInternal.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdt.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdc.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase1MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase2MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase3MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase4MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase5MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase6MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase1MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase2MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase3MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase4MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase5MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase6MiltonUsdc.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase1MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase5MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase6MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase7MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase8MiltonDai.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";

contract MiltonUtils is Test {
    struct ItfMiltons {
        ItfMiltonUsdt itfMiltonUsdt;
        ItfMiltonUsdc itfMiltonUsdc;
        ItfMiltonDai itfMiltonDai;
    }

    struct MockCase0Miltons {
        MockCase0MiltonUsdt mockCase0MiltonUsdt;
        MockCase0MiltonUsdc mockCase0MiltonUsdc;
        MockCase0MiltonDai mockCase0MiltonDai;
    }

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
        ERC1967Proxy miltonFacadeDataProviderProxy =
        new ERC1967Proxy(address(miltonFacadeDataProviderImplementation), abi.encodeWithSignature( "initialize(address,address[],address[],address[],address[])", iporOracle, assets, miltons, miltonStorages, josephs));
        return IMiltonFacadeDataProvider(address(miltonFacadeDataProviderProxy));
    }

    function prepareMilton(IMiltonInternal milton, address joseph, address stanley) public {
        IMiltonStorage miltonStorage = IMiltonStorage(milton.getMiltonStorage());
        miltonStorage.setJoseph(joseph);
        miltonStorage.setMilton(address(milton));
        milton.setJoseph(joseph);
        milton.setupMaxAllowanceForAsset(joseph);
        milton.setupMaxAllowanceForAsset(stanley);
    }

    function getItfMiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ItfMiltonUsdt) {
        ItfMiltonUsdt itfMiltonUsdtImplementation = new ItfMiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(itfMiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        return ItfMiltonUsdt(address(miltonUsdtProxy));
    }

    function getItfMiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ItfMiltonUsdc) {
        ItfMiltonUsdc itfMiltonUsdcImplementation = new ItfMiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(itfMiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        return ItfMiltonUsdc(address(miltonUsdcProxy));
    }

    function getItfMiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ItfMiltonDai) {
        ItfMiltonDai itfMiltonDaiImplementation = new ItfMiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(itfMiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return ItfMiltonDai(address(miltonDaiProxy));
    }

    function getItfMiltons(
        address iporOracle,
        address miltonSpreadModel,
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (ItfMiltons memory) {
        ItfMiltons memory mockCase0Miltons;
        mockCase0Miltons.itfMiltonUsdt =
            getItfMiltonUsdt(tokenUsdt, iporOracle, miltonStorageAddresses[0], miltonSpreadModel, stanleyAddresses[0]);
        mockCase0Miltons.itfMiltonUsdc =
            getItfMiltonUsdc(tokenUsdc, iporOracle, miltonStorageAddresses[1], miltonSpreadModel, stanleyAddresses[1]);
        mockCase0Miltons.itfMiltonDai =
            getItfMiltonDai(tokenDai, iporOracle, miltonStorageAddresses[2], miltonSpreadModel, stanleyAddresses[2]);
        return mockCase0Miltons;
    }

    function getMockCase0MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase0MiltonUsdt) {
        MockCase0MiltonUsdt mockCase0MiltonUsdtImplementation = new MockCase0MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase0MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        return MockCase0MiltonUsdt(address(miltonUsdtProxy));
    }

    function getMockCase0MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase0MiltonUsdc) {
        MockCase0MiltonUsdc mockCase0MiltonUsdcImplementation = new MockCase0MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase0MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        return MockCase0MiltonUsdc(address(miltonUsdcProxy));
    }

    function getMockCase0MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase0MiltonDai) {
        MockCase0MiltonDai mockCase0MiltonDaiImplementation = new MockCase0MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase0MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase0MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase0Miltons(
        address iporOracle,
        address miltonSpreadModel,
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai,
        address[] memory miltonStorageAddresses,
        address[] memory stanleyAddresses
    ) public returns (MockCase0Miltons memory) {
        MockCase0Miltons memory mockCase0Miltons;
        mockCase0Miltons.mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            tokenUsdt, iporOracle, miltonStorageAddresses[0], miltonSpreadModel, stanleyAddresses[0]
        );
        mockCase0Miltons.mockCase0MiltonUsdc = getMockCase0MiltonUsdc(
            tokenUsdc, iporOracle, miltonStorageAddresses[1], miltonSpreadModel, stanleyAddresses[1]
        );
        mockCase0Miltons.mockCase0MiltonDai = getMockCase0MiltonDai(
            tokenDai, iporOracle, miltonStorageAddresses[2], miltonSpreadModel, stanleyAddresses[2]
        );
        return mockCase0Miltons;
    }

    function getMockCase1MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase1MiltonUsdt) {
        MockCase1MiltonUsdt mockCase1MiltonUsdtImplementation = new MockCase1MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase1MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        return MockCase1MiltonUsdt(address(miltonUsdtProxy));
    }

    function getMockCase1MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase1MiltonUsdc) {
        MockCase1MiltonUsdc mockCase1MiltonUsdcImplementation = new MockCase1MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase1MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        return MockCase1MiltonUsdc(address(miltonUsdcProxy));
    }

    function getMockCase1MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase1MiltonDai) {
        MockCase1MiltonDai mockCase1MiltonDaiImplementation = new MockCase1MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase1MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase1MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase2MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase2MiltonUsdt) {
        MockCase2MiltonUsdt mockCase2MiltonUsdtImplementation = new MockCase2MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase2MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        return MockCase2MiltonUsdt(address(miltonUsdtProxy));
    }

    function getMockCase2MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase2MiltonUsdc) {
        MockCase2MiltonUsdc mockCase2MiltonUsdcImplementation = new MockCase2MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase2MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        return MockCase2MiltonUsdc(address(miltonUsdcProxy));
    }

    function getMockCase2MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase2MiltonDai) {
        MockCase2MiltonDai mockCase2MiltonDaiImplementation = new MockCase2MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase2MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase2MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase3MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase3MiltonUsdt) {
        MockCase3MiltonUsdt mockCase3MiltonUsdtImplementation = new MockCase3MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase3MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        return MockCase3MiltonUsdt(address(miltonUsdtProxy));
    }

    function getMockCase3MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase3MiltonUsdc) {
        MockCase3MiltonUsdc mockCase3MiltonUsdcImplementation = new MockCase3MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase3MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        return MockCase3MiltonUsdc(address(miltonUsdcProxy));
    }

    function getMockCase3MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase3MiltonDai) {
        MockCase3MiltonDai mockCase3MiltonDaiImplementation = new MockCase3MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase3MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase3MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase4MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase4MiltonDai) {
        MockCase4MiltonDai mockCase4MiltonDaiImplementation = new MockCase4MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase4MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase4MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase5MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase5MiltonDai) {
        MockCase5MiltonDai mockCase5MiltonDaiImplementation = new MockCase5MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase5MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase5MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase6MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (MockCase6MiltonUsdt) {
        MockCase6MiltonUsdt mockCase6MiltonUsdtImplementation = new MockCase6MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy =
        new ERC1967Proxy(address(mockCase6MiltonUsdtImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdt, iporOracle, miltonStorageUsdt, miltonSpreadModel, stanleyUsdt));
        return MockCase6MiltonUsdt(address(miltonUsdtProxy));
    }

    function getMockCase6MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (MockCase6MiltonUsdc) {
        MockCase6MiltonUsdc mockCase6MiltonUsdcImplementation = new MockCase6MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy =
        new ERC1967Proxy(address(mockCase6MiltonUsdcImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenUsdc, iporOracle, miltonStorageUsdc, miltonSpreadModel, stanleyUsdc));
        return MockCase6MiltonUsdc(address(miltonUsdcProxy));
    }

    function getMockCase6MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase6MiltonDai) {
        MockCase6MiltonDai mockCase6MiltonDaiImplementation = new MockCase6MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase6MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase6MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase7MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase7MiltonDai) {
        MockCase7MiltonDai mockCase7MiltonDaiImplementation = new MockCase7MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase7MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase7MiltonDai(address(miltonDaiProxy));
    }

    function getMockCase8MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (MockCase8MiltonDai) {
        MockCase8MiltonDai mockCase8MiltonDaiImplementation = new MockCase8MiltonDai();
        ERC1967Proxy miltonDaiProxy =
        new ERC1967Proxy(address(mockCase8MiltonDaiImplementation), abi.encodeWithSignature( "initialize(bool,address,address,address,address,address)", false, tokenDai, iporOracle, miltonStorageDai, miltonSpreadModel, stanleyDai));
        return MockCase8MiltonDai(address(miltonDaiProxy));
    }

    function prepareMiltonSpreadBaseUsdt() public returns (MockBaseMiltonSpreadModelUsdt) {
        return new MockBaseMiltonSpreadModelUsdt();
    }

    function prepareMiltonSpreadBaseUsdc() public returns (MockBaseMiltonSpreadModelUsdc) {
        return new MockBaseMiltonSpreadModelUsdc();
    }

    function prepareMiltonSpreadBaseDai() public returns (MockBaseMiltonSpreadModelDai) {
        return new MockBaseMiltonSpreadModelDai();
    }

    struct TestCaseWhenMiltonLostAndUserEarnedDai {
        uint256 openerUserLost;
        uint256 expectedMiltonUnderlyingTokenBalance;
        uint256 expectedOpenerUserUnderlyingTokenBalanceAfterClose;
        uint256 expectedCloserUserUnderlyingTokenBalanceAfterClose;
    }

    function getTestCaseWhenMiltonLostAndUserEarnedDai(
        uint256 openerUserLost,
        uint256 expectedMiltonUnderlyingTokenBalance,
        uint256 expectedOpenerUserUnderlyingTokenBalanceAfterClose,
        uint256 expectedCloserUserUnderlyingTokenBalanceAfterClose
    ) public pure returns (TestCaseWhenMiltonLostAndUserEarnedDai memory) {
        TestCaseWhenMiltonLostAndUserEarnedDai memory testCaseWhenMiltonLostAndUserEarned;
        testCaseWhenMiltonLostAndUserEarned.openerUserLost = openerUserLost;
        testCaseWhenMiltonLostAndUserEarned.expectedMiltonUnderlyingTokenBalance = expectedMiltonUnderlyingTokenBalance;
        testCaseWhenMiltonLostAndUserEarned.expectedOpenerUserUnderlyingTokenBalanceAfterClose =
            expectedOpenerUserUnderlyingTokenBalanceAfterClose;
        testCaseWhenMiltonLostAndUserEarned.expectedCloserUserUnderlyingTokenBalanceAfterClose =
            expectedCloserUserUnderlyingTokenBalanceAfterClose;
        return testCaseWhenMiltonLostAndUserEarned;
    }
}
