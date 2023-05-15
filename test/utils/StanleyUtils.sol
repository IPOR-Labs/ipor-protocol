// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/itf/ItfStanley.sol";
import "../../contracts/itf/ItfStanleyUsdt.sol";
import "../../contracts/itf/ItfStanleyDai.sol";
import "../../contracts/tokens/IvToken.sol";
import "../../contracts/vault/strategies/StrategyAave.sol";
import "../../contracts/vault/StanleyDai.sol";
import "../../contracts/vault/StanleyUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenCompoundUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveDai.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenCompoundDai.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenAaveUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetShareTokenCompoundUsdc.sol";
import "../../contracts/mocks/tokens/AAVEMockedToken.sol";
import "../../contracts/mocks/MockStanleyStrategies.sol";
import "../../contracts/mocks/stanley/MockCase2Stanley.sol";
import "../../contracts/mocks/stanley/aave/aTokens/MockAUsdt.sol";
import "../../contracts/mocks/stanley/aave/aTokens/MockAUsdc.sol";
import "../../contracts/mocks/stanley/aave/aTokens/MockADai.sol";
import "../../contracts/mocks/stanley/aave/MockADAI.sol";
import "../../contracts/mocks/stanley/aave/MockADAI.sol";
import "../../contracts/mocks/stanley/aave/MockLendingPoolAave.sol";
import "../../contracts/mocks/stanley/aave/MockProviderAave.sol";
import "../../contracts/mocks/stanley/aave/MockStakedAave.sol";
import "../../contracts/mocks/stanley/aave/MockAaveIncentivesController.sol";
import "../../contracts/mocks/stanley/compound/MockWhitePaper.sol";
import "../../contracts/mocks/stanley/compound/MockCToken.sol";
import "../../contracts/mocks/stanley/compound/MockComptroller.sol";
import "../../contracts/mocks/stanley/MockTestnetStrategy.sol";

import "../../contracts/mocks/tokens/MockedCOMPToken.sol";
import "../../contracts/vault/strategies/StrategyCompound.sol";

contract StanleyUtils {
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

    function getItfStanleyUsdt(address asset) public returns (ItfStanley itfStanley) {
        IvToken ivToken = new IvToken("IV USDT", "ivUSDT", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveUsdt(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundUsdt(asset);

        ItfStanleyUsdt itfStanleyImpl = new ItfStanleyUsdt();

        address itfStanleyProxyAddress = address(
            new ERC1967Proxy(
                address(itfStanleyImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    asset,
                    ivToken,
                    address(strategyAave),
                    address(strategyCompound)
                )
            )
        );

        ivToken.setStanley(itfStanleyProxyAddress);
        strategyAave.setStanley(itfStanleyProxyAddress);
        strategyCompound.setStanley(itfStanleyProxyAddress);

        return ItfStanley(itfStanleyProxyAddress);
    }

    function getItfStanleyDai(address asset) public returns (ItfStanley itfStanley) {
        IvToken ivToken = new IvToken("IV DAI", "ivDAI", asset);

        MockTestnetStrategy strategyAave = getMockTestnetStrategyAaveDai(asset);
        MockTestnetStrategy strategyCompound = getMockTestnetStrategyCompoundDai(asset);

        ItfStanleyDai itfStanleyImpl = new ItfStanleyDai();

        address itfStanleyProxyAddress = address(
            new ERC1967Proxy(
                address(itfStanleyImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    asset,
                    ivToken,
                    address(strategyAave),
                    address(strategyCompound)
                )
            )
        );

        ivToken.setStanley(itfStanleyProxyAddress);
        strategyAave.setStanley(itfStanleyProxyAddress);
        strategyCompound.setStanley(itfStanleyProxyAddress);

        return ItfStanley(itfStanleyProxyAddress);
    }

    function getItfStanleyDai(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public returns (ItfStanleyDai) {
        ItfStanleyDai itfStanleyImpl = new ItfStanleyDai();
        address itfStanleyProxyAddress = address(
            new ERC1967Proxy(
                address(itfStanleyImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address)",
                    asset,
                    ivToken,
                    strategyAave,
                    strategyCompound
                )
            )
        );
        return ItfStanleyDai(itfStanleyProxyAddress);
    }

    function getMockTestnetStrategyAaveUsdt(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyAaveUsdt strategyImpl = new MockTestnetStrategyAaveUsdt();
        MockTestnetShareTokenAaveUsdt shareToken = new MockTestnetShareTokenAaveUsdt(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyCompoundUsdt(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyCompoundUsdt strategyImpl = new MockTestnetStrategyCompoundUsdt();
        MockTestnetShareTokenCompoundUsdt shareToken = new MockTestnetShareTokenCompoundUsdt(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetStrategyAaveDai(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyAaveDai strategyImpl = new MockTestnetStrategyAaveDai();
        MockTestnetShareTokenAaveDai shareToken = new MockTestnetShareTokenAaveDai(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockTestnetShareTokenAaveUsdc(uint256 totalSupply) public returns (MockTestnetShareTokenAaveUsdc) {
        return new MockTestnetShareTokenAaveUsdc(totalSupply);
    }

    function getMockTestnetShareTokenCompoundUsdc(uint256 totalSupply)
        public
        returns (MockTestnetShareTokenCompoundUsdc)
    {
        return new MockTestnetShareTokenCompoundUsdc(totalSupply);
    }

    function getMockTestnetShareTokenAaveDai(uint256 totalSupply) public returns (MockTestnetShareTokenAaveDai) {
        return new MockTestnetShareTokenAaveDai(totalSupply);
    }

    function getMockTestnetShareTokenCompoundDai(uint256 totalSupply)
        public
        returns (MockTestnetShareTokenCompoundDai)
    {
        return new MockTestnetShareTokenCompoundDai(totalSupply);
    }

    function getMockTestnetStrategyCompoundDai(address asset) public returns (MockTestnetStrategy) {
        MockTestnetStrategyCompoundDai strategyImpl = new MockTestnetStrategyCompoundDai();
        MockTestnetShareTokenCompoundDai shareToken = new MockTestnetShareTokenCompoundDai(0);

        ERC1967Proxy strategyProxy = new ERC1967Proxy(
            address(strategyImpl),
            abi.encodeWithSignature("initialize(address,address)", asset, address(shareToken))
        );

        return MockTestnetStrategy(address(strategyProxy));
    }

    function getMockCase0Stanley(address asset) public returns (MockCaseBaseStanley) {
        MockCaseBaseStanley stanley = new MockCaseBaseStanley();
        stanley.setAsset(asset);
        return stanley;
    }

    function getMockCaseBaseStanley(address asset) public returns (MockCaseBaseStanley) {
        MockCaseBaseStanley stanley = new MockCaseBaseStanley();
        stanley.setAsset(asset);
        return stanley;
    }

    function _getMockCase0Stanleys(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    )
        internal
        returns (
            MockCaseBaseStanley,
            MockCaseBaseStanley,
            MockCaseBaseStanley
        )
    {
        MockCaseBaseStanley mockStanleyUsdt = new MockCaseBaseStanley();
        mockStanleyUsdt.setAsset(tokenUsdt);
        MockCaseBaseStanley mockStanleyUsdc = new MockCaseBaseStanley();
        mockStanleyUsdc.setAsset(tokenUsdc);
        MockCaseBaseStanley mockStanleyDai = new MockCaseBaseStanley();
        mockStanleyDai.setAsset(tokenDai);
        return (mockStanleyUsdt, mockStanleyUsdc, mockStanleyDai);
    }

    function getMockCase1Stanley(address asset) public returns (MockCaseBaseStanley) {
        MockCaseBaseStanley stanley = new MockCaseBaseStanley();
        stanley.setAsset(asset);
        return stanley;
    }

    function _getMockCase1Stanleys(
        address tokenUsdt,
        address tokenUsdc,
        address tokenDai
    )
        internal
        returns (
            MockCaseBaseStanley,
            MockCaseBaseStanley,
            MockCaseBaseStanley
        )
    {
        MockCaseBaseStanley mockStanleyUsdt = new MockCaseBaseStanley();
        mockStanleyUsdt.setAsset(tokenUsdt);
        MockCaseBaseStanley mockStanleyUsdc = new MockCaseBaseStanley();
        mockStanleyUsdc.setAsset(tokenUsdc);
        MockCaseBaseStanley mockStanleyDai = new MockCaseBaseStanley();
        mockStanleyDai.setAsset(tokenDai);
        return (mockStanleyUsdt, mockStanleyUsdc, mockStanleyDai);
    }

    function getMockCase2Stanley(address asset) public returns (MockCase2Stanley) {
        MockCase2Stanley stanley = new MockCase2Stanley();
        stanley.setAsset(asset);
        return stanley;
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

    function getStanleyDai(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public returns (StanleyDai) {
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
            address(stanleyDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(asset),
                address(ivToken),
                address(strategyAave),
                address(strategyCompound)
            )
        );
        return StanleyDai(address(stanleyDaiProxy));
    }

    function getStanleyUsdc(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public returns (StanleyUsdc) {
        StanleyUsdc stanleyUsdcImpl = new StanleyUsdc();
        ERC1967Proxy stanleyUsdcProxy = new ERC1967Proxy(
            address(stanleyUsdcImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(asset),
                address(ivToken),
                address(strategyAave),
                address(strategyCompound)
            )
        );
        return StanleyUsdc(address(stanleyUsdcProxy));
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
