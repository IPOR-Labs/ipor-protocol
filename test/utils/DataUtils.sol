// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdc.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/stanley/MockCaseBaseStanley.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfMilton.sol";
import "../../contracts/itf/ItfJoseph.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/MockIporWeighted.sol";

contract DataUtils is
    Test,
    IporOracleUtils,
    MiltonUtils,
    MiltonStorageUtils,
    JosephUtils,
    StanleyUtils
{
    struct IporProtocol {
        MockTestnetToken asset;
        IpToken ipToken;
        MockCaseBaseStanley stanley;
        MiltonStorage miltonStorage;
        ItfMilton milton;
        ItfJoseph joseph;
    }

    address internal _admin;
    address internal _userOne;

    function setupIporProtocolForUsdt() public returns (IporProtocol memory iporProtocol) {
        MockTestnetToken asset = getTokenUsdt();
        IpToken ipToken = getIpTokenUsdt(address(asset));
        MockCaseBaseStanley stanley = getMockCase0Stanley(address(asset));
        MiltonStorage miltonStorage = getMiltonStorage();

        address[] memory tokenAddresses = new address[](1);
        tokenAddresses[0] = address(asset);

        ItfIporOracle iporOracle = getIporOracleForManyAssets(
            _admin,
            _userOne,
            tokenAddresses,
            1,
            1,
            1
        );

        MockIporWeighted iporWeighted = _prepareIporWeighted(address(iporOracle));

        iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        MockSpreadModel miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);

        ItfMilton itfMilton = getItfMiltonUsdt(
            address(asset),
            address(iporOracle),
            address(miltonStorage),
            address(miltonSpreadModel),
            address(stanley)
        );

        ItfJoseph itfJoseph = getItfJosephUsdt(
            address(asset),
            address(ipToken),
            address(itfMilton),
            address(miltonStorage),
            address(stanley)
        );

        prepareIpToken(ipToken, address(itfJoseph));
        prepareJoseph(itfJoseph);
        prepareMilton(itfMilton, address(itfJoseph), address(stanley));

        iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        return IporProtocol(asset, ipToken, stanley, miltonStorage, itfMilton, itfJoseph);
    }

    function setupIporProtocolForDai() public returns (IporProtocol memory iporProtocol) {
        MockTestnetToken asset = getTokenDai();
        IpToken ipToken = getIpTokenDai(address(asset));
        MockCaseBaseStanley stanley = getMockCase0Stanley(address(asset));
        MiltonStorage miltonStorage = getMiltonStorage();

        address[] memory tokenAddresses = new address[](1);
        tokenAddresses[0] = address(asset);

        ItfIporOracle iporOracle = getIporOracleForManyAssets(
            _admin,
            _userOne,
            tokenAddresses,
            1,
            1,
            1
        );

        MockSpreadModel miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);

        MockIporWeighted iporWeighted = _prepareIporWeighted(address(iporOracle));
        iporOracle.setIporAlgorithmFacade(address(iporWeighted));

        ItfMilton itfMilton = getItfMiltonDai(
            address(asset),
            address(iporOracle),
            address(miltonStorage),
            address(miltonSpreadModel),
            address(stanley)
        );

        ItfJoseph itfJoseph = getItfJosephDai(
            address(asset),
            address(ipToken),
            address(itfMilton),
            address(miltonStorage),
            address(stanley)
        );

        prepareIpToken(ipToken, address(itfJoseph));
        prepareJoseph(itfJoseph);
        prepareMilton(itfMilton, address(itfJoseph), address(stanley));

        return IporProtocol(asset, ipToken, stanley, miltonStorage, itfMilton, itfJoseph);
    }

    function getTokenUsdt() public returns (MockTestnetTokenUsdt) {
        return new MockTestnetTokenUsdt(100000000000000 * 10**6);
    }

    function getTokenUsdc() public returns (MockTestnetTokenUsdc) {
        return new MockTestnetTokenUsdc(100000000000000 * 10**6);
    }

    function getTokenDai() public returns (MockTestnetTokenDai) {
        return new MockTestnetTokenDai(10000000000000000 * Constants.D18);
    }

    function getIpTokenUsdt(address tokenUsdt) public returns (IpToken) {
        return new IpToken("IP USDT", "ipUSDT", tokenUsdt);
    }

    function getIpTokenUsdc(address tokenUsdc) public returns (IpToken) {
        return new IpToken("IP USDC", "ipUSDC", tokenUsdc);
    }

    function getIpTokenDai(address tokenDai) public returns (IpToken) {
        return new IpToken("IP DAI", "ipDAI", tokenDai);
    }

    function prepareIpToken(IpToken ipToken, address joseph) public {
        ipToken.setJoseph(joseph);
    }
}
