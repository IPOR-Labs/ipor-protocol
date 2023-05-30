// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "./DeployerUtils.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../test/utils/TestConstants.sol";

contract AssetDeployer {
    struct DeployerData {
        DeployerUtils.AssetType assetType;
        string name;
        string symbol;
        uint256 initialSupply;
        uint8 decimals;
    }

    DeployerData private deployerData;

    function withAssetType(DeployerUtils.AssetType assetType) public returns (AssetDeployer) {
        deployerData.assetType = assetType;
        return this;
    }

    function withName(string memory name) public returns (AssetDeployer) {
        deployerData.name = name;
        return this;
    }

    function withSymbol(string memory symbol) public returns (AssetDeployer) {
        deployerData.symbol = symbol;
        return this;
    }

    function withInitialSupply(uint256 initialSupply) public returns (AssetDeployer) {
        deployerData.initialSupply = initialSupply;
        return this;
    }

    function withDecimals(uint8 decimals) public returns (AssetDeployer) {
        deployerData.decimals = decimals;
        return this;
    }

    function withUSDT() public returns (AssetDeployer) {
        deployerData.assetType = DeployerUtils.AssetType.USDT;
        deployerData.name = "Mocked USDT";
        deployerData.symbol = "USDT";
        deployerData.decimals = 6;
        deployerData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withUSDC() public returns (AssetDeployer) {
        deployerData.assetType = DeployerUtils.AssetType.USDC;
        deployerData.name = "Mocked USDC";
        deployerData.symbol = "USDC";
        deployerData.decimals = 6;
        deployerData.initialSupply = TestConstants.TOTAL_SUPPLY_6_DECIMALS;
        return this;
    }

    function withDAI() public returns (AssetDeployer) {
        deployerData.assetType = DeployerUtils.AssetType.DAI;
        deployerData.name = "Mocked DAI";
        deployerData.symbol = "DAI";
        deployerData.decimals = 18;
        deployerData.initialSupply = TestConstants.TOTAL_SUPPLY_18_DECIMALS;
        return this;
    }

    function build() public returns (MockTestnetToken) {
        MockTestnetToken token = new MockTestnetToken(
            deployerData.name,
            deployerData.symbol,
            deployerData.initialSupply,
            deployerData.decimals
        );

        return token;
    }
}
