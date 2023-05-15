// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../../contracts/tokens/IpToken.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../../../contracts/itf/ItfStanley.sol";
import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfJoseph.sol";
import "../../../contracts/amm/MiltonStorage.sol";
import "./AssetBuilder.sol";
import "./IpTokenBuilder.sol";
import "./IporOracleBuilder.sol";
import "./IporWeightedBuilder.sol";
import "./IporRiskManagementOracleBuilder.sol";
import "./MiltonStorageBuilder.sol";
import "./MockSpreadBuilder.sol";
import "./StanleyBuilder.sol";
import "./MiltonBuilder.sol";
import "./JosephBuilder.sol";
import "forge-std/Test.sol";

contract IporProtocolBuilder is Test {
    struct BuilderData {
        address asset;
        address iporOracle;
        address iporRiskManagementOracle;
    }

    struct IporProtocol {
        MockTestnetToken asset;
        IpToken ipToken;
        IvToken ivToken;
        ItfIporOracle iporOracle;
        IporRiskManagementOracle iporRiskManagementOracle;
        MockIporWeighted iporWeighted;
        MiltonStorage miltonStorage;
        MockSpreadModel spreadModel;
        ItfStanley stanley;
        ItfMilton milton;
        ItfJoseph joseph;
    }

    AssetBuilder public assetBuilder;
    IpTokenBuilder public ipTokenBuilder;
    IvTokenBuilder public ivTokenBuilder;
    IporOracleBuilder public iporOracleBuilder;
    IporRiskManagementOracleBuilder public iporRiskManagementOracleBuilder;
    IporWeightedBuilder public iporWeightedBuilder;
    MiltonStorageBuilder public miltonStorageBuilder;
    MockSpreadBuilder public spreadBuilder;
    StanleyBuilder public stanleyBuilder;
    MiltonBuilder public miltonBuilder;
    JosephBuilder public josephBuilder;

    address private _owner;

    BuilderData private builderData;

    constructor(address owner) {
        _owner = owner;
        assetBuilder = new AssetBuilder(owner, this);
        ipTokenBuilder = new IpTokenBuilder(owner, this);
        ivTokenBuilder = new IvTokenBuilder(owner, this);
        iporOracleBuilder = new IporOracleBuilder(owner, this);
        iporRiskManagementOracleBuilder = new IporRiskManagementOracleBuilder(owner, this);
        iporWeightedBuilder = new IporWeightedBuilder(owner, this);
        miltonStorageBuilder = new MiltonStorageBuilder(owner, this);
        spreadBuilder = new MockSpreadBuilder(owner, this);
        stanleyBuilder = new StanleyBuilder(owner, this);
        miltonBuilder = new MiltonBuilder(owner, this);
        josephBuilder = new JosephBuilder(owner, this);
    }

    function withAsset(address asset) public returns (IporProtocolBuilder) {
        builderData.asset = asset;
        ipTokenBuilder.withAsset(asset);
        ivTokenBuilder.withAsset(asset);
        iporOracleBuilder.withAsset(asset);
        iporRiskManagementOracleBuilder.withAsset(asset);
        stanleyBuilder.withAsset(asset);
        miltonBuilder.withAsset(asset);
        josephBuilder.withAsset(asset);

        return this;
    }

    function withIporOracle(address iporOracle) public returns (IporProtocolBuilder) {
        builderData.iporOracle = iporOracle;
        iporWeightedBuilder.withIporOracle(iporOracle);
        miltonBuilder.withIporOracle(iporOracle);
        return this;
    }

    function withIporRiskManagementOracle(address iporRiskManagementOracle) public returns (IporProtocolBuilder) {
        builderData.iporRiskManagementOracle = iporRiskManagementOracle;
        miltonBuilder.withIporRiskManagementOracle(iporRiskManagementOracle);
        return this;
    }

    function daiBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        josephBuilder.withAssetType(BuilderUtils.AssetType.DAI);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.DAI);

        assetBuilder.withDAI();

        return this;
    }

    function usdtBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDT);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDT);

        assetBuilder.withUSDT();

        return this;
    }

    function usdcBuilder() public returns (IporProtocolBuilder) {
        assetBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        miltonBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        josephBuilder.withAssetType(BuilderUtils.AssetType.USDC);
        stanleyBuilder.withAssetType(BuilderUtils.AssetType.USDC);

        assetBuilder.withUSDC();

        return this;
    }

    function asset() public view returns (AssetBuilder) {
        return assetBuilder;
    }

    function ipToken() public view returns (IpTokenBuilder) {
        return ipTokenBuilder;
    }

    function ivToken() public view returns (IvTokenBuilder) {
        return ivTokenBuilder;
    }

    function iporOracle() public view returns (IporOracleBuilder) {
        return iporOracleBuilder;
    }

    function iporRiskManagementOracle() public view returns (IporRiskManagementOracleBuilder) {
        return iporRiskManagementOracleBuilder;
    }

    function spread() public view returns (MockSpreadBuilder) {
        return spreadBuilder;
    }

    function milton() public view returns (MiltonBuilder) {
        return miltonBuilder;
    }

    function joseph() public view returns (JosephBuilder) {
        return josephBuilder;
    }

    function stanley() public view returns (StanleyBuilder) {
        return stanleyBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return this;
    }

    function build() public returns (IporProtocol memory iporProtocol) {
        MockTestnetToken asset;

        if (builderData.asset == address(0)) {
            asset = assetBuilder.build();
        } else {
            asset = MockTestnetToken(builderData.asset);
        }

        if (ipTokenBuilder.isSetAsset() == false) {
            ipTokenBuilder.withAsset(address(asset));
        }
        IpToken ipToken = ipTokenBuilder.build();

        if (ivTokenBuilder.isSetAsset() == false) {
            ivTokenBuilder.withAsset(address(asset));
        }
        IvToken ivToken = ivTokenBuilder.build();

        ItfIporOracle iporOracle;

        if (builderData.iporOracle == address(0)) {
            iporOracle = iporOracleBuilder.build();
        } else {
            iporOracle = ItfIporOracle(builderData.iporOracle);
        }

        IporRiskManagementOracle iporRiskManagementOracle;

        if (builderData.iporRiskManagementOracle == address(0)) {
            iporRiskManagementOracle = iporRiskManagementOracleBuilder.build();
        } else {
            iporRiskManagementOracle = IporRiskManagementOracle(builderData.iporRiskManagementOracle);
        }

        if (iporWeightedBuilder.isSetIporOracle() == false) {
            iporWeightedBuilder.withIporOracle(address(iporOracle));
        }
        MockIporWeighted iporWeighted = iporWeightedBuilder.build();

        MiltonStorage miltonStorage = miltonStorageBuilder.build();
        MockSpreadModel spreadModel = spreadBuilder.build();

        if (stanleyBuilder.isSetAsset() == false) {
            stanleyBuilder.withAsset(address(asset));
        }
        if (stanleyBuilder.isSetIvToken() == false) {
            stanleyBuilder.withIvToken(address(ivToken));
        }
        ItfStanley stanley = stanleyBuilder.build();

        if (miltonBuilder.isSetAsset() == false) {
            miltonBuilder.withAsset(address(asset));
        }
        if (miltonBuilder.isSetIporOracle() == false) {
            miltonBuilder.withIporOracle(address(iporOracle));
        }
        if (miltonBuilder.isSetMiltonStorage() == false) {
            miltonBuilder.withMiltonStorage(address(miltonStorage));
        }
        if (miltonBuilder.isSetStanley() == false) {
            miltonBuilder.withStanley(address(stanley));
        }
        if (miltonBuilder.isSetSpreadModel() == false) {
            miltonBuilder.withSpreadModel(address(spreadModel));
        }
        if (miltonBuilder.isSetIporRiskManagementOracle() == false) {
            miltonBuilder.withIporRiskManagementOracle(address(iporRiskManagementOracle));
        }

        ItfMilton milton = miltonBuilder.build();

        if (josephBuilder.isSetAsset() == false) {
            josephBuilder.withAsset(address(asset));
        }
        if (josephBuilder.isSetIpToken() == false) {
            josephBuilder.withIpToken(address(ipToken));
        }
        if (josephBuilder.isSetMiltonStorage() == false) {
            josephBuilder.withMiltonStorage(address(miltonStorage));
        }
        if (josephBuilder.isSetMilton() == false) {
            josephBuilder.withMilton(address(milton));
        }
        if (josephBuilder.isSetStanley() == false) {
            josephBuilder.withStanley(address(stanley));
        }

        ItfJoseph joseph = josephBuilder.build();

        vm.startPrank(address(_owner));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        ivToken.setStanley(address(stanley));

        miltonStorage.setMilton(address(milton));
        stanley.setMilton(address(milton));
        milton.setupMaxAllowanceForAsset(address(stanley));

        ipToken.setJoseph(address(joseph));
        miltonStorage.setJoseph(address(joseph));
        milton.setJoseph(address(joseph));
        milton.setupMaxAllowanceForAsset(address(joseph));

        joseph.setMaxLiquidityPoolBalance(1000000000);
        joseph.setMaxLpAccountContribution(1000000000);

        vm.stopPrank();

        iporProtocol = IporProtocol(
            asset,
            ipToken,
            ivToken,
            iporOracle,
            iporRiskManagementOracle,
            iporWeighted,
            miltonStorage,
            spreadModel,
            stanley,
            milton,
            joseph
        );

        delete builderData;
    }
}
