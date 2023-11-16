// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/oracles/IporOracle.sol";

contract IporOracleStEth is Test {
    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public constant oracleUpdater = 0xC3A53976E9855d815A08f577C2BEef2a799470b7;
    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant iporOracleProxy = 0x421C69EAa54646294Db30026aeE80D01988a6876;

    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
        vm.startPrank(owner);
        // random value for USDT/USDC/DAI
        IporOracle newImplementation = new IporOracle(USDT, 1e18, USDC, 1e18, DAI, 1e18, stETH);
        IporOracle(iporOracleProxy).upgradeTo(address(newImplementation));
        IporOracle(iporOracleProxy).addAsset(stETH, block.timestamp);
        vm.stopPrank();
    }

    function testShouldRevertWhenZeroAddressPassToConstructor() external {
        //when
        vm.expectRevert(
            abi.encodeWithSignature(
                "WrongAddress(address,string,string)",
                address(0x00),
                IporErrors.WRONG_ADDRESS,
                "constructor stEth"
            )
        );
        new IporOracle(USDT, 1e18, USDC, 1e18, DAI, 1e18, address(0x00));
    }

    function testShouldRevertWhenCallUpdateIndexWithStEth() external {
        //when
        vm.expectRevert(
            abi.encodeWithSignature(
                "WrongAddress(address,string,string)",
                stETH,
                IporErrors.WRONG_ADDRESS,
                "onlyAcceptStEth"
            )
        );
        vm.prank(oracleUpdater);
        IporOracle(iporOracleProxy).updateIndex(stETH, 1e18);
    }

    function testShouldRevertWhenCallUpdateIndexAndQuasiIbtPriceWithNotStEth() external {
        //when
        vm.expectRevert(
            abi.encodeWithSignature(
                "WrongAddress(address,string,string)",
                USDT,
                IporErrors.WRONG_ADDRESS,
                "onlyAcceptStEth"
            )
        );
        vm.prank(oracleUpdater);
        IporOracle(iporOracleProxy).updateIndexAndQuasiIbtPrice(USDT, 1e18, block.timestamp, 1e18);
    }

    function testShouldRevertWhenCallUpdateIndexAndQuasiIbtPriceWithUpdateTimestampOlderThanCurrentTimestamp()
        external
    {
        //when
        vm.expectRevert(
            abi.encodeWithSignature(
                "UpdateIndex(address,string,string)",
                stETH,
                IporOracleErrors.WRONG_INDEX_TIMESTAMP,
                "updateIndexAndQuasiIbtPrice"
            )
        );
        vm.prank(oracleUpdater);
        IporOracle(iporOracleProxy).updateIndexAndQuasiIbtPrice(stETH, 1e18, block.timestamp - 1, 1e18);
    }

    function testShouldRevertWhenCallUpdateIndexAndQuasiIbtPriceWithUpdateTimestampFromFuture() external {
        //when
        vm.prank(oracleUpdater);
        vm.expectRevert(
            abi.encodeWithSignature(
                "UpdateIndex(address,string,string)",
                stETH,
                IporOracleErrors.WRONG_INDEX_TIMESTAMP,
                "updateIndexAndQuasiIbtPrice"
            )
        );
        IporOracle(iporOracleProxy).updateIndexAndQuasiIbtPrice(stETH, 1e18, block.timestamp + 1, 1e18);
    }

    function testShouldRevertWhenIndexValueToBig() external {
        //given
        vm.warp(block.timestamp + 10);

        // when
        vm.prank(oracleUpdater);
        vm.expectRevert(stdError.arithmeticError);
        IporOracle(iporOracleProxy).updateIndexAndQuasiIbtPrice(stETH, type(uint64).max + 1, block.timestamp - 1, 1e18);
    }

    function testShouldRevertWhenNewQuasiIbtPriceToBig() external {
        //given
        vm.warp(block.timestamp + 10);

        // when
        vm.prank(oracleUpdater);
        vm.expectRevert(stdError.arithmeticError);
        IporOracle(iporOracleProxy).updateIndexAndQuasiIbtPrice(
            stETH,
            type(uint64).max,
            block.timestamp - 1,
            type(uint128).max + 1
        );
    }

    function testShouldUpdateIndex() external {
        //given
        (uint256 indexValueBefore, uint256 ibtPriceBefore, uint256 lastUpdateTimestampBefore) = IporOracle(
            iporOracleProxy
        ).getIndex(stETH);


        vm.warp(block.timestamp + 1000);

        //when
        vm.prank(oracleUpdater);
        IporOracle(iporOracleProxy).updateIndexAndQuasiIbtPrice(
            stETH,
            12e16,
            block.timestamp - 100,
            123e16
        );

        //then
        (uint256 indexValueAfter, uint256 ibtPriceAfter, uint256 lastUpdateTimestampAfter) = IporOracle(
            iporOracleProxy
        ).getIndex(stETH);

        assertEq(indexValueAfter, 12e16);
        assertEq(ibtPriceAfter, 1000000039003044901);
        assertEq(lastUpdateTimestampAfter, block.timestamp - 100);
        assertEq(indexValueBefore, 0);
        assertEq(ibtPriceBefore, 1e18);
        assertEq(lastUpdateTimestampBefore, block.timestamp - 1000);

    }
}
