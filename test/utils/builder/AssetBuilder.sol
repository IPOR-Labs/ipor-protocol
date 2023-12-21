// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "./BuilderUtils.sol";
import "../../mocks/tokens/MockTestnetToken.sol";
import "../../mocks/tokens/MockTestnetTokenStEth.sol";
import "../../utils/TestConstants.sol";
import "forge-std/Test.sol";

contract AssetBuilder is Test {
    struct BuilderData {
        BuilderUtils.AssetType assetType;
        string name;
        string symbol;
        uint256 initialSupply;
        uint8 decimals;
    }

    BuilderData private builderData;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (AssetBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withName(string memory name) public returns (AssetBuilder) {
        builderData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (AssetBuilder) {
        builderData.symbol = symbol;
        return this;
    }

    function withInitialSupply(uint256 initialSupply) public returns (AssetBuilder) {
        builderData.initialSupply = initialSupply;
        return this;
    }

    function withDecimals(uint8 decimals) public returns (AssetBuilder) {
        builderData.decimals = decimals;
        return this;
    }

    function withUSDT() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.USDT;
        builderData.name = "Mocked USDT";
        builderData.symbol = "USDT";
        builderData.decimals = 6;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withUSDC() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.USDC;
        builderData.name = "Mocked USDC";
        builderData.symbol = "USDC";
        builderData.decimals = 6;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withDAI() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.DAI;
        builderData.name = "Mocked DAI";
        builderData.symbol = "DAI";
        builderData.decimals = 18;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_18_DECIMALS;
        return this;
    }

    function withStEth() public returns (AssetBuilder) {
        builderData.assetType = BuilderUtils.AssetType.ST_ETH;
        builderData.name = "Mocked stETH";
        builderData.symbol = "stETH";
        builderData.decimals = 18;
        builderData.initialSupply = TestConstants.TOTAL_SUPPLY_18_DECIMALS;
        return this;
    }

    function build() public returns (MockTestnetToken) {
        vm.startPrank(_owner);

        MockTestnetToken token;

        if (builderData.assetType == BuilderUtils.AssetType.ST_ETH) {
            token = new MockTestnetTokenStEth(
                builderData.name,
                builderData.symbol,
                builderData.initialSupply,
                builderData.decimals
            );
        } else {
            token = new MockTestnetToken(
                builderData.name,
                builderData.symbol,
                builderData.initialSupply,
                builderData.decimals
            );
        }

        vm.stopPrank();

        delete builderData;

        return token;
    }
}
