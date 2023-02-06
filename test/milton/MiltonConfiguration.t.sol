// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonDai.sol";
import "../../contracts/amm/MiltonUsdc.sol";
import "../../contracts/amm/MiltonUsdt.sol";
import "../../contracts/mocks/stanley/aave/TestERC20.sol";
import "../../contracts/interfaces/IMiltonInternal.sol";

contract MiltonConfiguration is Test, TestCommons {
    MiltonDai internal _miltonConfiguration;

    function setUp() public {
        _miltonConfiguration = new MiltonDai();
    }

    function testShouldCreateMiltonUsdt() public {
        // when
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(6);
        MiltonUsdt miltonUsdtImplementation = new MiltonUsdt();
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(miltonUsdtImplementation),
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
        IMiltonInternal miltonUsdt = IMiltonInternal(address(miltonUsdtProxy));
        assertEq(miltonUsdt.getAsset(), address(usdt));
    }

    function testShouldCreateMiltonUsdc() public {
        // when
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(6);
        MiltonUsdc miltonUsdcImplementation = new MiltonUsdc();
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(miltonUsdcImplementation),
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
        IMiltonInternal miltonUsdc = IMiltonInternal(address(miltonUsdcProxy));
        assertEq(miltonUsdc.getAsset(), address(usdc));
    }

    function testShouldCreateMiltonDai() public {
        // when
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(18);
        MiltonDai miltonDaiImplementation = new MiltonDai();
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(miltonDaiImplementation),
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
        IMiltonInternal miltonDai = IMiltonInternal(address(miltonDaiProxy));
        assertEq(miltonDai.getAsset(), address(dai));
    }

    function testShouldRevertInitializerUsdtWhenMismatchAssetAndMiltonDecimals() public {
        // when
        TestERC20 usdt = new TestERC20(2**255);
        usdt.setDecimals(8);
        MiltonUsdt miltonUsdtImplementation = new MiltonUsdt();
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        ERC1967Proxy miltonUsdtProxy = new ERC1967Proxy(
            address(miltonUsdtImplementation),
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
        TestERC20 usdc = new TestERC20(2**255);
        usdc.setDecimals(8);
        MiltonUsdc miltonUsdcImplementation = new MiltonUsdc();
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        ERC1967Proxy miltonUsdcProxy = new ERC1967Proxy(
            address(miltonUsdcImplementation),
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
        TestERC20 dai = new TestERC20(2**255);
        dai.setDecimals(8);
        MiltonDai miltonDaiImplementation = new MiltonDai();
        vm.expectRevert(abi.encodePacked("IPOR_001"));
        ERC1967Proxy miltonDaiProxy = new ERC1967Proxy(
            address(miltonDaiImplementation),
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
        assertEq(actualValue, 5 * TestConstants.D16);
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
        assertEq(actualValue, 100 * TestConstants.D18);
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
