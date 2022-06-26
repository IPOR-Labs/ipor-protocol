// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

library PaginationUtils {
    function resolveResultSetSize(
        uint256 totalSwapNumber,
        uint256 offset,
        uint256 chunkSize
    ) internal pure returns (uint256) {
        uint256 resultSetSize;
        if (offset > totalSwapNumber) {
            resultSetSize = 0;
        } else if (offset + chunkSize < totalSwapNumber) {
            resultSetSize = chunkSize;
        } else {
            resultSetSize = totalSwapNumber - offset;
        }

        return resultSetSize;
    }
}
