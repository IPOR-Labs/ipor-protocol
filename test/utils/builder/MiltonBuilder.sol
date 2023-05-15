// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfMiltonUsdt.sol";
import "../../../contracts/itf/ItfMiltonUsdc.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";
import "../../../contracts/itf/ItfStanley.sol";
import "../../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../../contracts/mocks/MockIporWeighted.sol";
import "../../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase1MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase2MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase3MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase4MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase5MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase6MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase7MiltonDai.sol";
import "../../../contracts/mocks/milton/MockCase8MiltonDai.sol";

import "../../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase1MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase2MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase3MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase4MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase5MiltonUsdt.sol";
import "../../../contracts/mocks/milton/MockCase6MiltonUsdt.sol";

import "../../../contracts/mocks/milton/MockCase0MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase1MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase2MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase3MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase4MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase5MiltonUsdc.sol";
import "../../../contracts/mocks/milton/MockCase6MiltonUsdc.sol";

import "./AssetBuilder.sol";
import "./BuilderUtils.sol";
import "./IporOracleBuilder.sol";
import "./IporWeightedBuilder.sol";
import "./MockSpreadBuilder.sol";
import "./MiltonStorageBuilder.sol";
import "../../../contracts/itf/ItfIporOracle.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Test.sol";
import "./IporProtocolBuilder.sol";

contract MiltonBuilder is Test {
    struct BuilderData {
        BuilderUtils.MiltonTestCase testCase;
        BuilderUtils.AssetType assetType;
        address asset;
        address iporOracle;
        address iporRiskManagementOracle;
        address miltonStorage;
        address spreadModel;
        address stanley;
    }

    BuilderData private builderData;

    address private _owner;
    IporProtocolBuilder private _iporProtocolBuilder;

    constructor(address owner, IporProtocolBuilder iporProtocolBuilder) {
        _owner = owner;
        _iporProtocolBuilder = iporProtocolBuilder;
    }

    function and() public view returns (IporProtocolBuilder) {
        return _iporProtocolBuilder;
    }

    function withTestCase(BuilderUtils.MiltonTestCase testCase) public returns (MiltonBuilder) {
        builderData.testCase = testCase;
        return this;
    }

    function withAssetType(BuilderUtils.AssetType assetType) public returns (MiltonBuilder) {
        builderData.assetType = assetType;
        return this;
    }

    function withAsset(address asset) public returns (MiltonBuilder) {
        builderData.asset = asset;
        return this;
    }

    function withIporOracle(address iporOracle) public returns (MiltonBuilder) {
        builderData.iporOracle = iporOracle;
        return this;
    }

    function withIporRiskManagementOracle(address iporRiskManagementOracle) public returns (MiltonBuilder) {
        builderData.iporRiskManagementOracle = iporRiskManagementOracle;
        return this;
    }

    function withMiltonStorage(address miltonStorage) public returns (MiltonBuilder) {
        builderData.miltonStorage = miltonStorage;
        return this;
    }

    function withSpreadModel(address spreadModel) public returns (MiltonBuilder) {
        builderData.spreadModel = spreadModel;
        return this;
    }

    function withStanley(address stanley) public returns (MiltonBuilder) {
        builderData.stanley = stanley;
        return this;
    }

    function isSetAsset() public view returns (bool) {
        return builderData.asset != address(0);
    }

    function isSetIporOracle() public view returns (bool) {
        return builderData.iporOracle != address(0);
    }

    function isSetIporRiskManagementOracle() public view returns (bool) {
        return builderData.iporRiskManagementOracle != address(0);
    }

    function isSetMiltonStorage() public view returns (bool) {
        return builderData.miltonStorage != address(0);
    }

    function isSetSpreadModel() public view returns (bool) {
        return builderData.spreadModel != address(0);
    }

    function isSetStanley() public view returns (bool) {
        return builderData.stanley != address(0);
    }

    function build() public returns (ItfMilton) {
        vm.startPrank(_owner);
        ERC1967Proxy miltonProxy = _constructProxy(_buildMiltonImplementation());
        ItfMilton milton = ItfMilton(address(miltonProxy));
        vm.stopPrank();
        delete builderData;
        return milton;
    }

    function _buildMiltonImplementation() internal returns (address miltonImpl) {
        if (builderData.assetType == BuilderUtils.AssetType.DAI) {
            miltonImpl = address(
                _constructMiltonDaiImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else if (builderData.assetType == BuilderUtils.AssetType.USDT) {
            miltonImpl = address(
                _constructMiltonUsdtImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else if (builderData.assetType == BuilderUtils.AssetType.USDC) {
            miltonImpl = address(
                _constructMiltonUsdcImplementation(builderData.testCase, builderData.iporRiskManagementOracle)
            );
        } else {
            revert("Unsupported asset type");
        }
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        require(builderData.asset != address(0), "Asset address is required");
        require(builderData.iporOracle != address(0), "IporOracle address is required");
        require(builderData.miltonStorage != address(0), "MiltonStorage address is required");
        require(builderData.spreadModel != address(0), "SpreadModel address is required");
        require(builderData.stanley != address(0), "Stanley address is required");

        proxy = new ERC1967Proxy(
            impl,
            abi.encodeWithSignature(
                "initialize(bool,address,address,address,address,address)",
                false,
                builderData.asset,
                builderData.iporOracle,
                builderData.miltonStorage,
                builderData.spreadModel,
                builderData.stanley
            )
        );
    }

    function _constructMiltonDaiImplementation(BuilderUtils.MiltonTestCase testCase, address iporRiskManagementOracle)
        internal
        returns (ItfMilton)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");

        if (testCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            return new ItfMiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE0) {
            return new MockCase0MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return new MockCase1MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return new MockCase2MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return new MockCase3MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return new MockCase4MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return new MockCase5MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return new MockCase6MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE7) {
            return new MockCase7MiltonDai(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE8) {
            return new MockCase8MiltonDai(iporRiskManagementOracle);
        } else {
            revert("Unsupported test case");
        }
    }

    function _constructMiltonUsdtImplementation(BuilderUtils.MiltonTestCase testCase, address iporRiskManagementOracle)
        internal
        returns (ItfMilton)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");
        if (testCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            return new ItfMiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE0) {
            return new MockCase0MiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return new MockCase1MiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return new MockCase2MiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return new MockCase3MiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return new MockCase4MiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return new MockCase5MiltonUsdt(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return new MockCase6MiltonUsdt(iporRiskManagementOracle);
        } else {
            revert("Unsupported test case");
        }
    }

    function _constructMiltonUsdcImplementation(BuilderUtils.MiltonTestCase testCase, address iporRiskManagementOracle)
        internal
        returns (ItfMilton)
    {
        require(iporRiskManagementOracle != address(0), "iporRiskManagementOracle is required");
        if (testCase == BuilderUtils.MiltonTestCase.DEFAULT) {
            return new ItfMiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE0) {
            return new MockCase0MiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return new MockCase1MiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return new MockCase2MiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return new MockCase3MiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return new MockCase4MiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return new MockCase5MiltonUsdc(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return new MockCase6MiltonUsdc(iporRiskManagementOracle);
        } else {
            revert("Unsupported test case");
        }
    }
}
