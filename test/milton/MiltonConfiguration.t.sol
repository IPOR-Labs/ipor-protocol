// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonDai.sol";
import "../../contracts/amm/MiltonUsdc.sol";
import "../../contracts/amm/MiltonUsdt.sol";
import "../../contracts/mocks/stanley/aave/TestERC20.sol";

contract MiltonConfiguration is Test, TestCommons {
    MiltonDai internal _miltonConfiguration;
    address internal _admin;

    function setUp() public {
        _miltonConfiguration = new MiltonDai();
        _admin = address(this);
    }

    function testShouldCreateMiltonUsdt() public {
        // when
        ProxyTester miltonUsdtProxy = new ProxyTester();
        miltonUsdtProxy.setType("uups");
        MiltonUsdt miltonUsdtFactory = new MiltonUsdt();
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(6);
        address miltonUsdtAddress = miltonUsdtProxy.deploy(
            address(miltonUsdtFactory),
            _admin,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt)
            )
        );
        MiltonUsdt miltonUsdt = MiltonUsdt(miltonUsdtAddress);
        vm.prank(address(miltonUsdtProxy));
        assertEq(miltonUsdt.getAsset(), address(usdt));
    }

    function testShouldCreateMiltonUsdc() public {
        // when
        ProxyTester miltonUsdcProxy = new ProxyTester();
        miltonUsdcProxy.setType("uups");
        MiltonUsdc miltonUsdcFactory = new MiltonUsdc();
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(6);
        address miltonUsdcAddress = miltonUsdcProxy.deploy(
            address(miltonUsdcFactory),
            _admin,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc)
            )
        );
        MiltonUsdc miltonUsdc = MiltonUsdc(miltonUsdcAddress);
        vm.prank(address(miltonUsdcProxy));
        assertEq(miltonUsdc.getAsset(), address(usdc));
    }

    function testShouldCreateMiltonDai() public {
        // when
        ProxyTester miltonDaiProxy = new ProxyTester();
        miltonDaiProxy.setType("uups");
        MiltonDai miltonDaiFactory = new MiltonDai();
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(18);
        address miltonDaiAddress = miltonDaiProxy.deploy(
            address(miltonDaiFactory),
            _admin,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(dai),
                address(dai),
                address(dai),
                address(dai),
                address(dai)
            )
        );
        MiltonDai miltonDai = MiltonDai(miltonDaiAddress);
        vm.prank(address(miltonDaiProxy));
        assertEq(miltonDai.getAsset(), address(dai));
    }

    function testShouldRevertInitializerUsdtWhenMismatchAssetAndMiltonDecimals() public {
        // when
        ProxyTester miltonUsdtProxy = new ProxyTester();
        miltonUsdtProxy.setType("uups");
        MiltonUsdt miltonUsdtFactory = new MiltonUsdt();
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(8);
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        miltonUsdtProxy.deploy(
            address(miltonUsdtFactory),
            _admin,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt),
                address(usdt)
            )
        );
    }

    function testShouldRevertInitializeUsdcWhenMismatchAssetAndMiltonDecimals() public {
        // when
        ProxyTester miltonUsdcProxy = new ProxyTester();
        miltonUsdcProxy.setType("uups");
        MiltonUsdc miltonUsdcFactory = new MiltonUsdc();
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(8);
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        miltonUsdcProxy.deploy(
            address(miltonUsdcFactory),
            _admin,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc),
                address(usdc)
            )
        );
    }

    function testShouldRevertInitializerDaiWhenMismatchAssetAndMiltonDecimals() public {
        // when
        ProxyTester miltonDaiProxy = new ProxyTester();
        miltonDaiProxy.setType("uups");
        MiltonDai miltonDaiFactory = new MiltonDai();
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(8);
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        miltonDaiProxy.deploy(
            address(miltonDaiFactory),
            _admin,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                address(dai),
                address(dai),
                address(dai),
                address(dai),
                address(dai)
            )
        );
    }

    function testShouldSetupInitValueForMaxSwapTotalAmount() public {
        // when
        uint256 actualValue = _miltonConfiguration.getMaxSwapCollateralAmount();
        // then
        assertEq(actualValue, TestConstants.USD_100_000_18DEC);
    }

    function testShouldSetupInitValueForMaxLpUtilizationPercentage() public {
        // when
        uint256 actualValue = _miltonConfiguration.getMaxLpUtilizationRate();
        // then
        assertEq(actualValue, 8 * TestConstants.D17);
    }

    function testShouldSetupInitValueForMaxLpUtilizationPerLegPercentage() public {
        // when
        uint256 actualValue = _miltonConfiguration.getMaxLpUtilizationPerLegRate();
        // then
        assertEq(actualValue, 48 * TestConstants.D16);
    }

    function testShouldSetupInitValueForIncomeFeePercentage() public {
        // when
        uint256 actualValue = _miltonConfiguration.getIncomeFeeRate();
        // then
        assertEq(actualValue, 1 * TestConstants.D17);
    }

    function testShouldSetupInitValueForOpeningFeePercentage() public {
        // when
        uint256 actualValue = _miltonConfiguration.getOpeningFeeRate();
        // then
        assertEq(actualValue, 1 * TestConstants.D16);
    }

    function testShouldSetupInitValueForOpeningFeeTreasuryPercentage() public {
        // when
        uint256 actualValue = _miltonConfiguration.getOpeningFeeTreasuryPortionRate();
        // then
        assertEq(actualValue, TestConstants.ZERO);
    }

    function testShouldSetupInitValueForIporPublicationFeeAmount() public {
        // when
        uint256 actualValue = _miltonConfiguration.getIporPublicationFee();
        // then
        assertEq(actualValue, 10 * TestConstants.D18);
    }

    function testShouldSetupInitValueForLiquidationDepositAmountMethodOne() public {
        // when
        uint256 actualValue = _miltonConfiguration.getLiquidationDepositAmount();
        // then
        assertEq(actualValue, 25);
    }

    function testShouldSetupInitValueForLiquidationDepositAmountMethodTwo() public {
        // when
        uint256 actualValue = _miltonConfiguration.getWadLiquidationDepositAmount();
        // then
        assertEq(actualValue, 25 * TestConstants.D18);
    }

    function testShouldSetupInitValueForMaxLeverageValue() public {
        // when
        uint256 actualValue = _miltonConfiguration.getMaxLeverage();
        // then
        assertEq(actualValue, 1000 * TestConstants.D18);
    }

    function testShouldSetupInitValueForMinLeverageValue() public {
        // when
        uint256 actualValue = _miltonConfiguration.getMinLeverage();
        // then
        assertEq(actualValue, 10 * TestConstants.D18);
    }

    function testShouldInitValueForOpeningFeeTreasuryPercentageLowerThanOneHundredPercent() public {
        // when
        uint256 actualValue = _miltonConfiguration.getOpeningFeeTreasuryPortionRate();
        // then
        assertLe(actualValue, TestConstants.PERCENTAGE_100_18DEC);
    }

    function testShouldInitValueForIncomeFeePercentageLowerThanHundredPercent() public {
        // when
        uint256 actualValue = _miltonConfiguration.getIncomeFeeRate();
        // then
        assertLe(actualValue, TestConstants.PERCENTAGE_100_18DEC);
    }
}
