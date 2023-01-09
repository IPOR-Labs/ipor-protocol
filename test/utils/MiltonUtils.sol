// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdt.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdc.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelDai.sol";
import "../../contracts/facades/MiltonFacadeDataProvider.sol";
import "../../contracts/interfaces/IMiltonStorage.sol";
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
import "../../contracts/mocks/spread/MockSpreadModel.sol";

contract MiltonUtils is Test {
    /// ------------------- MILTON -------------------
    struct ItfMiltons {
        ERC1967Proxy itfMiltonUsdtProxy;
        ItfMiltonUsdt itfMiltonUsdt;
        ERC1967Proxy itfMiltonUsdcProxy;
        ItfMiltonUsdc itfMiltonUsdc;
        ERC1967Proxy itfMiltonDaiProxy;
        ItfMiltonDai itfMiltonDai;
    }

    struct MockCase0Miltons {
        ERC1967Proxy mockCase0MiltonUsdtProxy;
        MockCase0MiltonUsdt mockCase0MiltonUsdt;
        ERC1967Proxy mockCase0MiltonUsdcProxy;
        MockCase0MiltonUsdc mockCase0MiltonUsdc;
        ERC1967Proxy mockCase0MiltonDaiProxy;
        MockCase0MiltonDai mockCase0MiltonDai;
    }

    /// ------------------- MILTON -------------------

    /// ------------------- SPREAD MODEL -------------------
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

    /// ------------------- SPREAD MODEL -------------------

    /// ------------------- MILTON FACADE DATA PROVIDER -------------------
    function getMiltonFacadeDataProvider(
        address iporOracle,
        address[] memory assets,
        address[] memory miltons,
        address[] memory miltonStorages,
        address[] memory josephs
    ) public returns (ERC1967Proxy, MiltonFacadeDataProvider) {
        MiltonFacadeDataProvider miltonFacadeDataProviderImpl = new MiltonFacadeDataProvider();

        ERC1967Proxy miltonFacadeDataProviderProxy = new ERC1967Proxy(
            address(miltonFacadeDataProviderImpl),
            abi.encodeWithSignature(
                "initialize(address,address[],address[],address[],address[])",
                iporOracle,
                assets,
                miltons,
                miltonStorages,
                josephs
            )
        );
        MiltonFacadeDataProvider miltonFacadeDataProvider = MiltonFacadeDataProvider(
            address(miltonFacadeDataProviderProxy)
        );
        return (miltonFacadeDataProviderProxy, miltonFacadeDataProvider);
    }

    /// ------------------- MILTON FACADE DATA PROVIDER -------------------

    /// ------------------- ITFMILTON -------------------
    function getItfMiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, ItfMiltonUsdt) {
        ItfMiltonUsdt itfMiltonUsdtImpl = new ItfMiltonUsdt();

        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(itfMiltonUsdtImpl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                iporOracle,
                miltonStorageUsdt,
                miltonSpreadModel,
                stanleyUsdt
            )
        );

        ItfMiltonUsdt itfMiltonUsdt = ItfMiltonUsdt(address(miltonUsdtProxy));

        return (miltonUsdtProxy, itfMiltonUsdt);
    }

    function prepareItfMiltonUsdt(
        ItfMiltonUsdt miltonUsdt,
        address josephUsdt,
        address stanleyUsdt
    ) public {
        vm.startPrank(address(this));
        IMiltonStorage miltonStorage = IMiltonStorage(miltonUsdt.getMiltonStorage());

        miltonStorage.setJoseph(josephUsdt);
        miltonUsdt.setJoseph(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
        vm.stopPrank();
    }

    function getItfMiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, ItfMiltonUsdc) {
        ItfMiltonUsdc itfMiltonUsdcImpl = new ItfMiltonUsdc();

        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(itfMiltonUsdcImpl),
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

        ItfMiltonUsdc itfMiltonUsdc = ItfMiltonUsdc(address(miltonUsdcProxy));

        return (miltonUsdcProxy, itfMiltonUsdc);
    }

    function prepareItfMiltonUsdc(
        ItfMiltonUsdc miltonUsdc,
        address miltonUsdcProxy,
        address josephUsdc,
        address stanleyUsdc
    ) public {
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setJoseph(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getItfMiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ERC1967Proxy, ItfMiltonDai) {
        ItfMiltonDai itfMiltonDaiImpl = new ItfMiltonDai();

        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(itfMiltonDaiImpl),
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
        ItfMiltonDai itfMiltonDai = ItfMiltonDai(address(miltonDaiProxy));
        return (miltonDaiProxy, itfMiltonDai);
    }

    function prepareItfMiltonDai(
        ItfMiltonDai miltonDai,
        address josephDai,
        address stanleyDai
    ) public {
        vm.startPrank(address(this));
        IMiltonStorage miltonStorage = IMiltonStorage(miltonDai.getMiltonStorage());

        miltonStorage.setJoseph(josephDai);
        miltonDai.setJoseph(josephDai);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
        vm.stopPrank();
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
        (mockCase0Miltons.itfMiltonUsdtProxy, mockCase0Miltons.itfMiltonUsdt) = getItfMiltonUsdt(
            tokenUsdt,
            iporOracle,
            miltonStorageAddresses[0],
            miltonSpreadModel,
            stanleyAddresses[0]
        );
        (mockCase0Miltons.itfMiltonUsdcProxy, mockCase0Miltons.itfMiltonUsdc) = getItfMiltonUsdc(
            tokenUsdc,
            iporOracle,
            miltonStorageAddresses[1],
            miltonSpreadModel,
            stanleyAddresses[1]
        );
        (mockCase0Miltons.itfMiltonDaiProxy, mockCase0Miltons.itfMiltonDai) = getItfMiltonDai(
            tokenDai,
            iporOracle,
            miltonStorageAddresses[2],
            miltonSpreadModel,
            stanleyAddresses[2]
        );
        return mockCase0Miltons;
    }

    function getItfMiltonAddresses(
        address miltonUsdt,
        address miltonUsdc,
        address miltonDai
    ) public pure returns (address[] memory) {
        address[] memory miltons = new address[](3);
        miltons[0] = miltonUsdt;
        miltons[1] = miltonUsdc;
        miltons[2] = miltonDai;
        return miltons;
    }

    /// ------------------- ITFMILTON -------------------

    /// ------------------- Mock Cases Milton -------------------

    function getMockCase0MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, MockCase0MiltonUsdt) {
        MockCase0MiltonUsdt mockCase0MiltonUsdtImpl = new MockCase0MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(mockCase0MiltonUsdtImpl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                iporOracle,
                miltonStorageUsdt,
                miltonSpreadModel,
                stanleyUsdt
            )
        );
        MockCase0MiltonUsdt mockCase0MiltonUsdt = MockCase0MiltonUsdt(address(miltonUsdtProxy));
        return (miltonUsdtProxy, mockCase0MiltonUsdt);
    }

    function prepareMockCase0MiltonUsdt(
        MockCase0MiltonUsdt miltonUsdt,
        address miltonUsdtProxy,
        address josephUsdt,
        address stanleyUsdt
    ) public {
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setJoseph(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase0MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, MockCase0MiltonUsdc) {
        MockCase0MiltonUsdc mockCase0MiltonUsdcImpl = new MockCase0MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(mockCase0MiltonUsdcImpl),
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
        MockCase0MiltonUsdc mockCase0MiltonUsdc = MockCase0MiltonUsdc(address(miltonUsdcProxy));
        return (miltonUsdcProxy, mockCase0MiltonUsdc);
    }

    function prepareMockCase0MiltonUsdc(
        MockCase0MiltonUsdc miltonUsdc,
        address miltonUsdcProxy,
        address josephUsdc,
        address stanleyUsdc
    ) public {
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setJoseph(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase0MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ERC1967Proxy, MockCase0MiltonDai) {
        MockCase0MiltonDai mockCase0MiltonDaiImpl = new MockCase0MiltonDai();
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(mockCase0MiltonDaiImpl),
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
        MockCase0MiltonDai mockCase0MiltonDai = MockCase0MiltonDai(address(miltonDaiProxy));
        return (miltonDaiProxy, mockCase0MiltonDai);
    }

    function prepareMockCase0MiltonDai(
        MockCase0MiltonDai miltonDai,
        address miltonDaiProxy,
        address josephDai,
        address stanleyDai
    ) public {
        vm.prank(miltonDaiProxy);
        miltonDai.setJoseph(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
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
        (
            mockCase0Miltons.mockCase0MiltonUsdtProxy,
            mockCase0Miltons.mockCase0MiltonUsdt
        ) = getMockCase0MiltonUsdt(
            tokenUsdt,
            iporOracle,
            miltonStorageAddresses[0],
            miltonSpreadModel,
            stanleyAddresses[0]
        );
        (
            mockCase0Miltons.mockCase0MiltonUsdcProxy,
            mockCase0Miltons.mockCase0MiltonUsdc
        ) = getMockCase0MiltonUsdc(
            tokenUsdc,
            iporOracle,
            miltonStorageAddresses[1],
            miltonSpreadModel,
            stanleyAddresses[1]
        );
        (
            mockCase0Miltons.mockCase0MiltonDaiProxy,
            mockCase0Miltons.mockCase0MiltonDai
        ) = getMockCase0MiltonDai(
            tokenDai,
            iporOracle,
            miltonStorageAddresses[2],
            miltonSpreadModel,
            stanleyAddresses[2]
        );
        return mockCase0Miltons;
    }

    function getMockCase0MiltonAddresses(
        address miltonUsdt,
        address miltonUsdc,
        address miltonDai
    ) public pure returns (address[] memory) {
        address[] memory miltons = new address[](3);
        miltons[0] = miltonUsdt;
        miltons[1] = miltonUsdc;
        miltons[2] = miltonDai;
        return miltons;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase1MiltonUsdt() public returns (MockCase1MiltonUsdt) {
        MockCase1MiltonUsdt mockCase1MiltonUsdt = new MockCase1MiltonUsdt();
        return mockCase1MiltonUsdt;
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase2MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, MockCase2MiltonUsdt) {
        MockCase2MiltonUsdt mockCase2MiltonUsdtImpl = new MockCase2MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(mockCase2MiltonUsdtImpl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                iporOracle,
                miltonStorageUsdt,
                miltonSpreadModel,
                stanleyUsdt
            )
        );
        MockCase2MiltonUsdt mockCase2MiltonUsdt = MockCase2MiltonUsdt(address(miltonUsdtProxy));
        return (miltonUsdtProxy, mockCase2MiltonUsdt);
    }

    function prepareMockCase2MiltonUsdt(
        MockCase2MiltonUsdt miltonUsdt,
        address miltonUsdtProxy,
        address josephUsdt,
        address stanleyUsdt
    ) public {
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setJoseph(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase2MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, MockCase2MiltonUsdc) {
        MockCase2MiltonUsdc mockCase2MiltonUsdcImpl = new MockCase2MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(mockCase2MiltonUsdcImpl),
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
        MockCase2MiltonUsdc mockCase2MiltonUsdc = MockCase2MiltonUsdc(address(miltonUsdcProxy));
        return (miltonUsdcProxy, mockCase2MiltonUsdc);
    }

    function prepareMockCase2MiltonUsdc(
        MockCase2MiltonUsdc miltonUsdc,
        address miltonUsdcProxy,
        address josephUsdc,
        address stanleyUsdc
    ) public {
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setJoseph(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase2MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ERC1967Proxy, MockCase2MiltonDai) {
        MockCase2MiltonDai mockCase2MiltonDaiImpl = new MockCase2MiltonDai();
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(mockCase2MiltonDaiImpl),
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
        MockCase2MiltonDai mockCase2MiltonDai = MockCase2MiltonDai(address(miltonDaiProxy));
        return (miltonDaiProxy, mockCase2MiltonDai);
    }

    function prepareMockCase2MiltonDai(
        MockCase2MiltonDai miltonDai,
        address miltonDaiProxy,
        address josephDai,
        address stanleyDai
    ) public {
        vm.prank(miltonDaiProxy);
        miltonDai.setJoseph(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase3MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, MockCase3MiltonUsdt) {
        MockCase3MiltonUsdt mockCase3MiltonUsdtImpl = new MockCase3MiltonUsdt();

        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(mockCase3MiltonUsdtImpl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                iporOracle,
                miltonStorageUsdt,
                miltonSpreadModel,
                stanleyUsdt
            )
        );
        MockCase3MiltonUsdt mockCase3MiltonUsdt = MockCase3MiltonUsdt(address(miltonUsdtProxy));
        return (miltonUsdtProxy, mockCase3MiltonUsdt);
    }

    function prepareMockCase3MiltonUsdt(
        MockCase3MiltonUsdt miltonUsdt,
        address miltonUsdtProxy,
        address josephUsdt,
        address stanleyUsdt
    ) public {
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setJoseph(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase3MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, MockCase3MiltonUsdc) {
        MockCase3MiltonUsdc mockCase3MiltonUsdcImpl = new MockCase3MiltonUsdc();

        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(mockCase3MiltonUsdcImpl),
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
        MockCase3MiltonUsdc mockCase3MiltonUsdc = MockCase3MiltonUsdc(address(miltonUsdcProxy));
        return (miltonUsdcProxy, mockCase3MiltonUsdc);
    }

    function prepareMockCase3MiltonUsdc(
        MockCase3MiltonUsdc miltonUsdc,
        address miltonUsdcProxy,
        address josephUsdc,
        address stanleyUsdc
    ) public {
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setJoseph(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase3MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ERC1967Proxy, MockCase3MiltonDai) {
        MockCase3MiltonDai mockCase3MiltonDaiImpl = new MockCase3MiltonDai();

        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(mockCase3MiltonDaiImpl),
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
        MockCase3MiltonDai mockCase3MiltonDai = MockCase3MiltonDai(address(miltonDaiProxy));
        return (miltonDaiProxy, mockCase3MiltonDai);
    }

    function prepareMockCase3MiltonDai(
        MockCase3MiltonDai miltonDai,
        address miltonDaiProxy,
        address josephDai,
        address stanleyDai
    ) public {
        vm.prank(miltonDaiProxy);
        miltonDai.setJoseph(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    /// ------------------------------------------------------------------------------------

    function getMockCase6MiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ERC1967Proxy, MockCase6MiltonUsdt) {
        MockCase6MiltonUsdt mockCase6MiltonUsdtImpl = new MockCase6MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(mockCase6MiltonUsdtImpl),
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                tokenUsdt,
                iporOracle,
                miltonStorageUsdt,
                miltonSpreadModel,
                stanleyUsdt
            )
        );
        MockCase6MiltonUsdt mockCase6MiltonUsdt = MockCase6MiltonUsdt(address(miltonUsdtProxy));
        return (miltonUsdtProxy, mockCase6MiltonUsdt);
    }

    function prepareMockCase6MiltonUsdt(
        MockCase6MiltonUsdt miltonUsdt,
        address miltonUsdtProxy,
        address josephUsdt,
        address stanleyUsdt
    ) public {
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setJoseph(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(josephUsdt);
        vm.prank(miltonUsdtProxy);
        miltonUsdt.setupMaxAllowanceForAsset(stanleyUsdt);
    }

    function getMockCase6MiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ERC1967Proxy, MockCase6MiltonUsdc) {
        MockCase6MiltonUsdc mockCase6MiltonUsdcImpl = new MockCase6MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(mockCase6MiltonUsdcImpl),
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
        MockCase6MiltonUsdc mockCase6MiltonUsdc = MockCase6MiltonUsdc(address(miltonUsdcProxy));
        return (miltonUsdcProxy, mockCase6MiltonUsdc);
    }

    function prepareMockCase6MiltonUsdc(
        MockCase6MiltonUsdc miltonUsdc,
        address miltonUsdcProxy,
        address josephUsdc,
        address stanleyUsdc
    ) public {
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setJoseph(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(josephUsdc);
        vm.prank(miltonUsdcProxy);
        miltonUsdc.setupMaxAllowanceForAsset(stanleyUsdc);
    }

    function getMockCase6MiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ERC1967Proxy, MockCase6MiltonDai) {
        MockCase6MiltonDai mockCase6MiltonDaiImpl = new MockCase6MiltonDai();
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(mockCase6MiltonDaiImpl),
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
        MockCase6MiltonDai mockCase6MiltonDai = MockCase6MiltonDai(address(miltonDaiProxy));
        return (miltonDaiProxy, mockCase6MiltonDai);
    }

    function prepareMockCase6MiltonDai(
        MockCase6MiltonDai miltonDai,
        address miltonDaiProxy,
        address josephDai,
        address stanleyDai
    ) public {
        vm.prank(miltonDaiProxy);
        miltonDai.setJoseph(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(josephDai);
        vm.prank(miltonDaiProxy);
        miltonDai.setupMaxAllowanceForAsset(stanleyDai);
    }

    /// ------------------- Mock Cases Milton -------------------

    /// ------------------- Mock Cases Milton Spread -------------------
    function prepareMiltonSpreadBaseUsdt() public returns (MockBaseMiltonSpreadModelUsdt) {
        MockBaseMiltonSpreadModelUsdt mockBaseMiltonSpreadModelUsdt = new MockBaseMiltonSpreadModelUsdt();
        return mockBaseMiltonSpreadModelUsdt;
    }

    function prepareMiltonSpreadBaseUsdc() public returns (MockBaseMiltonSpreadModelUsdc) {
        MockBaseMiltonSpreadModelUsdc mockBaseMiltonSpreadModelUsdc = new MockBaseMiltonSpreadModelUsdc();
        return mockBaseMiltonSpreadModelUsdc;
    }

    function prepareMiltonSpreadBaseDai() public returns (MockBaseMiltonSpreadModelDai) {
        MockBaseMiltonSpreadModelDai mockBaseMiltonSpreadModelDai = new MockBaseMiltonSpreadModelDai();
        return mockBaseMiltonSpreadModelDai;
    }

    /// ------------------- Mock Cases Milton Spread -------------------

    /// ------------------- Milton Test Cases -------------------

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
        testCaseWhenMiltonLostAndUserEarned
            .expectedMiltonUnderlyingTokenBalance = expectedMiltonUnderlyingTokenBalance;
        testCaseWhenMiltonLostAndUserEarned
            .expectedOpenerUserUnderlyingTokenBalanceAfterClose = expectedOpenerUserUnderlyingTokenBalanceAfterClose;
        testCaseWhenMiltonLostAndUserEarned
            .expectedCloserUserUnderlyingTokenBalanceAfterClose = expectedCloserUserUnderlyingTokenBalanceAfterClose;
        return testCaseWhenMiltonLostAndUserEarned;
    }
}
