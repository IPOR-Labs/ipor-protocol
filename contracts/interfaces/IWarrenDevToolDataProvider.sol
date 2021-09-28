// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

interface IWarrenDevToolDataProvider {

    struct IporFront {

        //@notice Asset Symbol like USDT, USDC, DAI etc.
        string asset;

        //@notice IPOR Index Value
        uint256 indexValue;

        //@notice Interest Bearing Token Price
        uint256 ibtPrice;

        //@notice block timestamp
        uint256 blockTimestamp;
    }

    function getIndexes() external view returns (IporFront[] memory);

}