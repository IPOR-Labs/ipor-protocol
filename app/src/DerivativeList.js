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
                <th scope="col">Notional Amount</th>
                <th scope="col">Deposit Amount</th>
                <th scope="col">Start Date</th>
                <th scope="col">End Date</th>
                <th scope="col">Fixed Rate</th>
                <th scope="col">SOAP</th>
                <th scope="col">IPOR Index</th>
                <th scope="col">Interest Bearing Token Value</th>
                <th scope="col">Interest Bearing Token Quantity</th>
            </tr>
            </thead>
            <tbody>
            {derivatives.map(derivative => (
                <tr key={derivative.id}>
                    <td>{derivative.id}</td>
                    <td>{derivative.buyer}</td>
                    <td>{derivative.asset}</td>
                    <td>{derivative.notionalAmount}</td>
                    <td>{derivative.depositAmount}</td>
                    <td>{toDate(derivative.startingTimestamp)}</td>
                    <td>{toDate(derivative.endingTimestamp)}</td>
                    <td>{derivative.indicator.fixedRate}</td>
                    <td>{derivative.indicator.soap}</td>
                    <td>{derivative.indicator.iporIndexValue}</td>
                    <td>{derivative.indicator.ibtPrice}</td>
                    <td>{derivative.indicator.ibtQuantity}</td>
                    {/*<td>{toDate(derivative.end)}</td>                    */}
                </tr>
            ))}
            </tbody>
        </table>
    ) : <p>No derivatives yet</p>
);
