// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./IporPoolStorage.sol";

/**
 * @title Liquidity Pool for Automated Market Maker
 *
 * @author IPOR Labs
 */
contract IporPool is IporPoolV1Storage {


    constructor(string memory _ticker) {
        admin = msg.sender;
        ticker = _ticker;
    }

    /**
     * @notice adds liquidity to the IPOR Pool to offer derivatives against
     * @param _amount amount of deposited asset
     * @return iporAssetToMint amount of minted IPOR asset TODO: fix description
     */
    function mint(uint256 _amount) external returns (uint256) {
        //TODO: require amount > 0
        //TODO: require(token.transferFrom(msg.sender, address(this), _amount), "Cherrypool::deposit liquidity failed");
        //TODO: token.approve(address(cToken), _amount);
        //TODO: ??? assert(cToken.mint(_amount) == 0);
    }

    function redeem(uint256 _amount) external isLongUtilized() isShortUtilized() returns (uint256) {
    }


    function calculateLongPoolUtilization(uint256 _longPoolReserved) public view returns (uint256) {
    }

    function calculateShortPoolUtilization(uint256 _shortPoolReserved) public view returns (uint256) {
    }

    function payout(address _redeemer, uint256 _redeemedDaiAmount, uint256 _redeemedCherryDaiTokens) internal {
    }

    function _reserveLongPool(uint256 _amount) internal canReserveLong(_amount) {
        //TODO: reqire amount

        //longPoolReserved = longPoolReserved.add(_amount);
    }

    function _reserveShortPool(uint256 _amount) internal canReserveShort(_amount) {
        //TODO:
        //require(_amount > 0, "Cherrypool::invalid amount to reserve");

        //        shortPoolReserved = shortPoolReserved.add(_amount);
    }

    function _releaseAssetFromLongPool(uint256 _amount) internal {
        //TODO: require
        //        require(_amount > 0, "Cherrypool::invalid amount to free");
        // longPoolReserved.sub(_amount);
        //TODO: event
        //        emit FreeLongPool(_amount);
    }

    function _releaseAssetFromShortPool(uint256 _amount) internal {
        //TODO: require
        //        require(_amount > 0, "Cherrypool::invalid amount to free");
        // shortPoolReserved.sub(_amount);
        //TODO: event
        //        emit FreeShortPool(_amount);
    }

    function _freeShortPool(uint256 _amount) pure internal {
        require(_amount > 0, "Cherrypool::invalid amount to free");
        // shortPoolReserved.sub(_amount);

        // emit FreeShortPool(_amount);
    }

    modifier isLongUtilized() {
        //TODO: user defined parameters for pool
        _;
    }

    modifier isShortUtilized() {
        //TODO: user defined parameters for pool
        _;
    }

    modifier canReserveLong(uint256 _amount) {
        //TODO: check if long pool does not have liquidity
        _;
    }

    modifier canReserveShort(uint256 _amount) {
        //TODO: check if long pool does not have liquidity
        _;
    }
}