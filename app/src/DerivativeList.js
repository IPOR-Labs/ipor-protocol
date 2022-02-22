import React from "react";
import { toDate } from "./utils";
// import { Link } from "react-router-dom";

export default (derivatives) =>
    derivatives && derivatives.length > 0 ? (
        <table className="table">
            <thead>
                <tr>
                    <th scope="col">id</th>
                    <th scope="col">Buyer</th>
                    <th scope="col">Collateral</th>
                    <th scope="col">Notional</th>
                    <th scope="col">Fee Liquidation Deposit Amount</th>
                    <th scope="col">Interest Bearing Token Quantity</th>
                    <th scope="col">Fixed Interest Rate</th>
                    <th scope="col">Start Date</th>
                    <th scope="col">End Date</th>
                </tr>
            </thead>
            <tbody>
                {derivatives.map((derivative) => {
                    if (derivative.state == 1) {
                        return (
                            <tr key={derivative.id}>
                                <td>{derivative.id}</td>
                                <td>{derivative.buyer}</td>
                                <td>
                                    {derivative.collateral /
                                        1000000000000000000}
                                    <br />
                                    <small>{derivative.collateral}</small>
                                </td>
                                <td>
                                    {derivative.notionalAmount /
                                        1000000000000000000}
                                    <br />
                                    <small>{derivative.notionalAmount}</small>
                                </td>
                                <td>
                                    {derivative.liquidationDepositAmount /
                                        1000000000000000000}
                                    <br />
                                    <small>
                                        {derivative.liquidationDepositAmount}
                                    </small>
                                </td>
                                <td>
                                    {derivative.ibtQuantity /
                                        1000000000000000000}
                                    <br />
                                    <small>{derivative.ibtQuantity}</small>
                                </td>
                                <td>
                                    {derivative.fixedInterestRate /
                                        1000000000000000000}
                                    <br />
                                    <small>
                                        {derivative.fixedInterestRate}
                                    </small>
                                </td>
                                <td>{toDate(derivative.startingTimestamp)}</td>
                                <td>{toDate(derivative.endingTimestamp)}</td>
                            </tr>
                        );
                    }
                })}
            </tbody>
        </table>
    ) : (
        <p>No derivatives yet</p>
    );
