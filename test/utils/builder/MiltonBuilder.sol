// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "../../../contracts/itf/ItfMilton.sol";
import "../../../contracts/itf/ItfMiltonUsdt.sol";
import "../../../contracts/itf/ItfMiltonUsdc.sol";
import "../../../contracts/itf/ItfMiltonDai.sol";

import "../../../contracts/mocks/milton/MockCase0Milton6D.sol";
import "../../../contracts/mocks/milton/MockCase1Milton6D.sol";
import "../../../contracts/mocks/milton/MockCase2Milton6D.sol";
import "../../../contracts/mocks/milton/MockCase3Milton6D.sol";
import "../../../contracts/mocks/milton/MockCase4Milton6D.sol";
import "../../../contracts/mocks/milton/MockCase5Milton6D.sol";
import "../../../contracts/mocks/milton/MockCase6Milton6D.sol";

import "../../../contracts/mocks/milton/MockCase0Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase1Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase2Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase3Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase4Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase5Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase6Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase7Milton18D.sol";
import "../../../contracts/mocks/milton/MockCase8Milton18D.sol";


import "./BuilderUtils.sol";
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
            return new MockCase0Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return new MockCase1Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return new MockCase2Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return new MockCase3Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return new MockCase4Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return new MockCase5Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return new MockCase6Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE7) {
            return new MockCase7Milton18D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE8) {
            return new MockCase8Milton18D(iporRiskManagementOracle);
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
            return new MockCase0Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return new MockCase1Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return new MockCase2Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return new MockCase3Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return new MockCase4Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return new MockCase5Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return new MockCase6Milton6D(iporRiskManagementOracle);
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
            return new MockCase0Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE1) {
            return new MockCase1Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE2) {
            return new MockCase2Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE3) {
            return new MockCase3Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE4) {
            return new MockCase4Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE5) {
            return new MockCase5Milton6D(iporRiskManagementOracle);
        } else if (testCase == BuilderUtils.MiltonTestCase.CASE6) {
            return new MockCase6Milton6D(iporRiskManagementOracle);
        } else {
            revert("Unsupported test case");
        }
    }
}
