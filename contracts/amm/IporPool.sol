// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.4 <0.9.0;

import "./IporPoolStorage.sol";

/**
 * @title Liquidity Pool for Automated Market Maker
 *
 * @author IPOR Labs
 */
contract IporPool is IporPoolV1Storage {

    constructor(address _token) {
        admin = msg.sender;
        token = _token;
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

    function redeem(uint256 _amount) external isPayFixUtilized() isRecFixUtilized() returns (uint256) {
    }


    function calculatePayFixedPoolUtilization(uint256 _payFixedPoolReserved) public view returns (uint256) {
    }

    function calculateRecFixedPoolUtilization(uint256 _recFixedPoolReserved) public view returns (uint256) {
    }

    /**
     * @notice Transfer the underlying asset
     * @param _redeemer redeemer address
     * @param _redeemedTokenAmount amount of Token to transfer
     * @param _redeemedIpTokenAmount amount of IpToken to burn
     */
    function payout(address _redeemer, uint256 _redeemedTokenAmount, uint256 _redeemedIpTokenAmount) internal {
    }

    function _reservePayFixPool(uint256 _amount) internal canReservePayFix(_amount) {
        //TODO: reqire amount

        //longPoolReserved = longPoolReserved.add(_amount);
    }

    function _reserveRecFixPool(uint256 _amount) internal canReserveRecFix(_amount) {
        //TODO:
        //require(_amount > 0, "Cherrypool::invalid amount to reserve");

        //        shortPoolReserved = shortPoolReserved.add(_amount);
    }

    function _releaseAssetFromPayFixPool(uint256 _amount) internal {
        //TODO: require
        //        require(_amount > 0, "Cherrypool::invalid amount to free");
        // longPoolReserved.sub(_amount);
        //TODO: event
        //        emit FreeLongPool(_amount);
    }

    function _releaseAssetFromRecFixPool(uint256 _amount) internal {
        //TODO: require
        //        require(_amount > 0, "Cherrypool::invalid amount to free");
        // shortPoolReserved.sub(_amount);
        //TODO: event
        //        emit FreeShortPool(_amount);
    }

    function _freeRecFixPool(uint256 _amount) pure internal {
        require(_amount > 0, "Cherrypool::invalid amount to free");
        // shortPoolReserved.sub(_amount);

        // emit FreeShortPool(_amount);
    }

    modifier isPayFixUtilized() {
        //TODO: user defined parameters for pool
        _;
    }

    modifier isRecFixUtilized() {
        //TODO: user defined parameters for pool
        _;
    }

    modifier canReservePayFix(uint256 _amount) {
        //TODO: check if long pool does not have liquidity
        _;
    }

    modifier canReserveRecFix(uint256 _amount) {
        //TODO: check if long pool does not have liquidity
        _;
    }
}