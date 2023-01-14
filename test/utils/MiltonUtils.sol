// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../contracts/interfaces/IMiltonStorage.sol";
import "../../contracts/interfaces/IMiltonInternal.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonUsdc.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";

contract MiltonUtils is Test {
    function getItfMiltonUsdt(
        address tokenUsdt,
        address iporOracle,
        address miltonStorageUsdt,
        address miltonSpreadModel,
        address stanleyUsdt
    ) public returns (ItfMiltonUsdt) {
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

        return ItfMiltonUsdt(address(miltonUsdtProxy));
    }

    function getItfMiltonUsdc(
        address tokenUsdc,
        address iporOracle,
        address miltonStorageUsdc,
        address miltonSpreadModel,
        address stanleyUsdc
    ) public returns (ItfMiltonUsdc) {
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

        return ItfMiltonUsdc(address(miltonUsdcProxy));
    }

    function getItfMiltonDai(
        address tokenDai,
        address iporOracle,
        address miltonStorageDai,
        address miltonSpreadModel,
        address stanleyDai
    ) public returns (ItfMiltonDai) {
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
        return ItfMiltonDai(address(miltonDaiProxy));
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

    function prepareMockSpreadModel(
        uint256 calculateQuotePayFixedValue,
        uint256 calculateQuoteReceiveFixedValue,
        int256 calculateSpreadPayFixedValue,
        int256 calculateSpreadReceiveFixedVaule
    ) public returns (MockSpreadModel) {
        return
            new MockSpreadModel(
                calculateQuotePayFixedValue,
                calculateQuoteReceiveFixedValue,
                calculateSpreadPayFixedValue,
                calculateSpreadReceiveFixedVaule
            );
    }
}
