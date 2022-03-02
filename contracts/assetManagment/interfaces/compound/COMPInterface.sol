pragma solidity 0.8.9;

interface COMPInterface {
    function delegate(address delegatee) external;

    function delegates(address) external view returns (address);
}
