// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IporTypes} from "contracts/interfaces/types/IporTypes.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";

contract IporOracleTest is Test {
    using stdStorage for StdStorage;

    uint32 private _blockTimestamp = 1641701;
    address private iporAlgorithmFacade;
    MockTestnetToken private _daiTestnetToken;
    MockTestnetToken private _usdcTestnetToken;
    MockTestnetToken private _usdtTestnetToken;
    IporOracle private _iporOracle;

    function setUp() public {
        vm.warp(_blockTimestamp);
        iporAlgorithmFacade = address(0);
        (_daiTestnetToken, _usdcTestnetToken, _usdtTestnetToken) = _getStables();

        IporOracle iporOracleImplementation = new IporOracle(
            iporAlgorithmFacade,
            address(_usdcTestnetToken),
            Constants.D18,
            address(_usdtTestnetToken),
            Constants.D18,
            address(_daiTestnetToken),
            Constants.D18
        );
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
            abi.encodeWithSignature("initialize(address[],uint32[])", assets, updateTimestamps)
        );
        _iporOracle = IporOracle(address(iporOracleProxy));

        _iporOracle.addUpdater(address(this));
    }

    function testShouldCalculateIbtPriceForFixedRate() public {
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, Constants.D18);
        _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);

        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 1 days),
            1000082195158658879
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 7 days),
            1000575508006975985
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 30 days),
            1002468795894779595
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 180 days),
            1014904501167913392
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 365 days),
            1030454533953516856
        );
        assertEq(
            _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp + 730 days),
            1061836546545359623
        );
    }

    function testShouldCalculateIbtPriceForFixedRateAndPublicationsInOneDayInterval() public {
        // given
        vm.warp(_blockTimestamp);
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, Constants.D18);
        _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);

        // when
        for (uint256 i; i < 365; ++i) {
            vm.warp(block.timestamp + 1 days);
            _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);
        }

        // then
        assertEq(_iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp), 1030454533953516856);
    }

    function testShouldCalculateIbtPriceForFixedRateAndPublicationsInSevenDaysInterval() public {
        // given
        vm.warp(_blockTimestamp);
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, Constants.D18);
        _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);

        // when
        for (uint256 i; i < 52; ++i) {
            vm.warp(block.timestamp + 7 days);
            _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);
        }
        vm.warp(block.timestamp + 1 days);
        _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);

        // then
        assertEq(_iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp), 1030454533953516856);
    }

    function testShouldCalculateIbtPriceAfterUpgrade() public {
        // given
        vm.warp(_blockTimestamp);
        uint256 ibtPrice = _iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), _blockTimestamp);
        assertEq(ibtPrice, Constants.D18);
        _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);
        vm.warp(_blockTimestamp + 180 days);

        // when
        IporOracle newImplementation = new IporOracle(
            iporAlgorithmFacade,
            address(_usdcTestnetToken),
            1014904501167913392,
            address(_usdtTestnetToken),
            1014904501167913392,
            address(_daiTestnetToken),
            1014904501167913392
        );
        _iporOracle.upgradeTo(address(newImplementation));
        address[] memory assets = new address[](1);
        assets[0] = address(_daiTestnetToken);
        _iporOracle.postUpgrade(assets);
        _iporOracle.updateIndex(address(_daiTestnetToken), 3e16);

        // then
        vm.warp(block.timestamp + 185 days);
        assertEq(_iporOracle.calculateAccruedIbtPrice(address(_daiTestnetToken), block.timestamp), 1030454533953516858); //lost precision at 18th decimal place
    }

    // TODO remove it after test fixing
    function _getStables()
        internal
        returns (
            MockTestnetToken dai,
            MockTestnetToken usdc,
            MockTestnetToken usdt
        )
    {
        dai = new MockTestnetToken("Mocked DAI", "DAI", 100_000_000 * 1e18, uint8(18));
        usdc = new MockTestnetToken("Mocked USDC", "USDC", 100_000_000 * 1e6, uint8(6));
        usdt = new MockTestnetToken("Mocked USDT", "USDT", 100_000_000 * 1e6, uint8(6));
    }
}
