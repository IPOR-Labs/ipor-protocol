// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/mocks/MockIporWeighted.sol";
import {IporTypes} from "contracts/interfaces/types/IporTypes.sol";
import "./MockOldIporOracleV2.sol";
import "./MockItfIporOracleV2.sol";

contract IporOracleTest is Test, TestCommons {
    using stdStorage for StdStorage;

    uint32 private _blockTimestamp = 1641701;
    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    ItfIporOracle private _iporOracle;

    function setUp() public {
        vm.warp(_blockTimestamp);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        ItfIporOracle iporOracleImplementation = new ItfIporOracle();
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint32[] memory updateTimestamps = new uint32[](3);
        updateTimestamps[0] = uint32(_blockTimestamp);
        updateTimestamps[1] = uint32(_blockTimestamp);
        updateTimestamps[2] = uint32(_blockTimestamp);

        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(iporOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint32[])",
                assets,
                updateTimestamps
            )
        );
        _iporOracle = ItfIporOracle(address(iporOracleProxy));

        _iporOracle.addUpdater(address(this));
    }


    function testShouldCalculateInitialInterestBearingTokenPrice() public {
        // given
        uint256 iporIndexValue = 5e16;
        // when
        _iporOracle.itfUpdateIndex(
            address(_daiTestnetToken),
            iporIndexValue,
            _blockTimestamp + 60 * 60
        );
        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(
            address(_daiTestnetToken)
        );

        assertEq(iporIndexAfter, iporIndexValue);
        assertEq(ibtPriceAfter, 1e18);
    }

    function testShouldCalculateNextInterestBearingTokenPriceOneYearPeriod() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 51e15;
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueOne, updateDate);
        updateDate += 365 * 24 * 60 * 60;

        // when
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueTwo, updateDate);

        // then
        uint256 expectedIbtPrice = 105e16;
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(
            address(_daiTestnetToken)
        );

        assertEq(iporIndexAfter, indexValueTwo);
        assertEq(ibtPriceAfter, expectedIbtPrice);
    }

    function testShouldCalculateNextInterestBearingTokenPriceOneMonthPeriod() public {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 51e15;
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueOne, updateDate);
        updateDate += 30 * 24 * 60 * 60;

        // when
        _iporOracle.itfUpdateIndex(address(_daiTestnetToken), indexValueTwo, updateDate);

        // then
        uint256 expectedIbtPrice = 1004109589041095890;
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(
            address(_daiTestnetToken)
        );

        assertEq(iporIndexAfter, indexValueTwo);
        assertEq(ibtPriceAfter, expectedIbtPrice);
    }

    function testShouldCalculateDifferentInterestBearingTokenPriceOneSecondPeriodSameIporIndexValue6DecimalsAsset()
        public
    {
        // given
        uint256 updateDate = _blockTimestamp + 60 * 60;
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 5e16;
        _iporOracle.itfUpdateIndex(address(_usdcTestnetToken), indexValueOne, updateDate);
        updateDate++;
        (uint256 iporIndexBefore, uint256 ibtPriceBefore, ) = _iporOracle.getIndex(
            address(_usdcTestnetToken)
        );
        // when
        _iporOracle.itfUpdateIndex(address(_usdcTestnetToken), indexValueTwo, updateDate);

        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(
            address(_usdcTestnetToken)
        );

        assertEq(iporIndexBefore, indexValueOne);
        assertEq(iporIndexAfter, indexValueTwo);

        assertEq(iporIndexAfter, iporIndexBefore);

        assertEq(ibtPriceBefore != ibtPriceAfter, true);
    }

    function testShouldCalculateNextAfterNextInterestBearingTokenPriceHalfYearAndThreeMonthsSnapshots() public {
        // given
        uint256 indexValueOne = 5e16;
        uint256 indexValueTwo = 6e16;
        uint256 iporIndexThirdValue = 7e16;
        uint256 expectedIbtPrice = 104e16;

        uint256 updateDate = _blockTimestamp + 60 * 60;
        vm.warp(updateDate);
        _iporOracle.updateIndex(address(_usdtTestnetToken), indexValueOne);

        updateDate += (365 * 24 * 60 * 60) / 2;
        vm.warp(updateDate);
        _iporOracle.updateIndex(address(_usdtTestnetToken), indexValueTwo);

        updateDate += (365 * 24 * 60 * 60) / 4;
        vm.warp(updateDate);

        // when
        _iporOracle.updateIndex(address(_usdtTestnetToken), iporIndexThirdValue);

        // then
        (uint256 iporIndexAfter, uint256 ibtPriceAfter, ) = _iporOracle.getIndex(address(_usdtTestnetToken));

        assertEq(iporIndexAfter, iporIndexThirdValue);
        assertEq(ibtPriceAfter, expectedIbtPrice);
    }

    function testShouldUpdateImplementationOnProxy() public {
        // given
        address[] memory assets = new address[](3);
        assets[0] = address(_daiTestnetToken);
        assets[1] = address(_usdcTestnetToken);
        assets[2] = address(_usdtTestnetToken);

        uint32[] memory updateTimestamps = new uint32[](3);
        updateTimestamps[0] = uint32(_blockTimestamp);
        updateTimestamps[1] = uint32(_blockTimestamp);
        updateTimestamps[2] = uint32(_blockTimestamp);

        uint256[] memory firstIndexValues = new uint256[](3);
        firstIndexValues[0] = 7e16;
        firstIndexValues[1] = 7e16;
        firstIndexValues[2] = 7e16;

        MockItfIporOracleV2 oldIporOracleImplementation = new MockItfIporOracleV2();
        ItfIporOracle newIporOracleImplementation = new ItfIporOracle();
        ERC1967Proxy iporOracleProxy = new ERC1967Proxy(
            address(oldIporOracleImplementation),
            abi.encodeWithSignature(
                "initialize(address[],uint32[])",
                assets,
                updateTimestamps
            )
        );
        address proxyAddress = address(iporOracleProxy);
        MockItfIporOracleV2(proxyAddress).addUpdater(address(this));

        MockIporWeighted algorithmImplementation = new MockIporWeighted();
        ERC1967Proxy algorithmProxy = new ERC1967Proxy(
            address(algorithmImplementation),
            abi.encodeWithSignature("initialize(address)", address(_iporOracle))
        );

        MockItfIporOracleV2(proxyAddress).itfUpdateIndexes(
            assets,
            firstIndexValues,
            _blockTimestamp
        );

        (uint256 indexValueDaiBefore, , ) = MockOldIporOracleV2(proxyAddress).getIndex(
            address(_daiTestnetToken)
        );
        (uint256 indexValueUsdcBefore, , ) = MockOldIporOracleV2(proxyAddress).getIndex(
            address(_usdcTestnetToken)
        );
        (uint256 indexValueUsdtBefore, , ) = MockOldIporOracleV2(proxyAddress).getIndex(
            address(_usdtTestnetToken)
        );

        // when
        MockOldIporOracleV2(proxyAddress).upgradeTo(address(newIporOracleImplementation));
        ItfIporOracle(proxyAddress).setIporAlgorithmFacade(address(algorithmProxy));

        (uint256 indexValueDaiAfterUpdateImplementation, , ) = ItfIporOracle(proxyAddress)
            .getIndex(address(_daiTestnetToken));
        (uint256 indexValueUsdcAfterUpdateImplementation, , ) = ItfIporOracle(proxyAddress)
            .getIndex(address(_usdcTestnetToken));
        (uint256 indexValueUsdtAfterUpdateImplementation, , ) = ItfIporOracle(proxyAddress)
            .getIndex(address(_usdtTestnetToken));

        ItfIporOracle(proxyAddress).updateIndex(address(_daiTestnetToken));
        ItfIporOracle(proxyAddress).updateIndex(address(_usdcTestnetToken));
        ItfIporOracle(proxyAddress).updateIndex(address(_usdtTestnetToken));

        // then

        (uint256 indexValueDaiAfterUpdateIndex, , ) = ItfIporOracle(proxyAddress).getIndex(
            address(_daiTestnetToken)
        );
        (uint256 indexValueUsdcAfterUpdateIndex, , ) = ItfIporOracle(proxyAddress).getIndex(
            address(_usdcTestnetToken)
        );
        (uint256 indexValueUsdtAfterUpdateIndex, , ) = ItfIporOracle(proxyAddress).getIndex(
            address(_usdtTestnetToken)
        );

        assertEq(indexValueDaiBefore, 7e16);
        assertEq(indexValueUsdcBefore, 7e16);
        assertEq(indexValueUsdtBefore, 7e16);
        assertEq(indexValueDaiAfterUpdateImplementation, indexValueDaiBefore);
        assertEq(indexValueUsdcAfterUpdateImplementation, indexValueUsdcBefore);
        assertEq(indexValueUsdtAfterUpdateImplementation, indexValueUsdtBefore);
        assertTrue(indexValueDaiAfterUpdateIndex != indexValueDaiAfterUpdateImplementation);
        assertTrue(indexValueUsdcAfterUpdateIndex != indexValueUsdcAfterUpdateImplementation);
        assertTrue(indexValueUsdtAfterUpdateIndex != indexValueUsdtAfterUpdateImplementation);
    }

}
