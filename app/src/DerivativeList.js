import React from "react";
// import { Link } from "react-router-dom";
import {toDate} from "./utils.js";

export default (derivatives) => (
    derivatives && derivatives.length > 0 ? (
        <table className="table">
            <thead>
            <tr>
                <th scope="col">id</th>
                <th scope="col">Buyer</th>
                <th scope="col">Asset</th>
                <th scope="col">Direction</th>
                <th scope="col">Deposit Amount</th>
                <th scope="col">Fee Liquidation Deposit Amount</th>
                <th scope="col">Fee Opening Amount</th>
                <th scope="col">Fee IPOR publication Amount</th>
                <th scope="col">Spread percentage</th>
                <th scope="col">Leverage</th>
                <th scope="col">Notional Amount</th>
                <th scope="col">Start Date</th>
                <th scope="col">End Date</th>
                <th scope="col">IPOR Index Value</th>
                <th scope="col">Interest Bearing Token Price</th>
                <th scope="col">Interest Bearing Token Quantity</th>
                <th scope="col">Fixed Interest Rate</th>
                <th scope="col">SOAP</th>

            </tr>
            </thead>
            <tbody>
            {derivatives.map(derivative => (
                <tr key={derivative.id}>
                    <td>{derivative.id}</td>
                    <td>{derivative.buyer}</td>
                    <td>{derivative.asset}</td>
                    <td>{derivative.direction}</td>
                    <td>{derivative.depositAmount / 1000000000000000000}</td>
                    <td>{derivative.fee.liquidationDepositAmount  / 1000000000000000000}</td>
                    <td>{derivative.fee.openingAmount  / 1000000000000000000}</td>
                    <td>{derivative.fee.iporPublicationAmount  / 1000000000000000000}</td>
                    <td>{derivative.fee.spreadPercentage  / 1000000000000000000}</td>
                    <td>{derivative.leverage}</td>
                    <td>{derivative.notionalAmount  / 1000000000000000000}</td>
                    <td>{toDate(derivative.startingTimestamp)}</td>
                    <td>{toDate(derivative.endingTimestamp)}</td>
                    <td>{derivative.indicator.iporIndexValue  / 1000000000000000000}</td>
                    <td>{derivative.indicator.ibtPrice  / 1000000000000000000}</td>
                    <td>{derivative.indicator.ibtQuantity  / 1000000000000000000}</td>
                    <td>{derivative.indicator.fixedInterestRate  / 1000000000000000000}</td>
                    <td>{derivative.indicator.soap  / 1000000000000000000}</td>
                </tr>
            ))}
            </tbody>
        </table>
    ) : <p>No derivatives yet</p>
);
