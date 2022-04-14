import React from "react";
import { toDate } from "./utils";
// import { Link } from "react-router-dom";

export default (response) =>
    response && response.swaps && response.swaps.length > 0 ? (
        <div>
            <table className="table">
                <thead>
                    <tr>
                        <th scope="col">id</th>
                        <th scope="col">Asset</th>
                        <th scope="col">Collateral</th>
                        <th scope="col">Notional Amount</th>
                        <th scope="col">Leverage</th>
                        <th scope="col">Direction</th>
                        <th scope="col">Fixed Interest Rate</th>
                        <th scope="col">Position Value</th>
                        <th scope="col">Starting Timestamp</th>
                        <th scope="col">Ending Timestamp</th>
                        <th scope="col">Liquidation Deposit Amount</th>
                    </tr>
                </thead>
                <tbody>
                    {response.swaps.map((derivative) => {
                        return (
                            <tr key={derivative.id}>
                                <td>{derivative.id}</td>
                                <td>{derivative.asset}</td>
                                <td>
                                    {derivative.collateral / 1000000000000000000}
                                    <br />
                                    <small>{derivative.collateral}</small>
                                </td>
                                <td>
                                    {derivative.notional / 1000000000000000000}
                                    <br />
                                    <small>{derivative.notional}</small>
                                </td>
                                <td>{derivative.leverage}</td>
                                <td>{derivative.direction}</td>
                                <td>
                                    {derivative.fixedInterestRate / 1000000000000000000}
                                    <br />
                                    <small>{derivative.fixedInterestRate}</small>
                                </td>
                                <td>
                                    {derivative.payoff / 1000000000000000000}
                                    <br />
                                    <small>{derivative.payoff}</small>
                                </td>
                                <td>{toDate(derivative.openTimestamp)}</td>
                                <td>{toDate(derivative.endTimestamp)}</td>
                                <td>{derivative.liquidationDepositAmount}</td>
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </div>
    ) : (
        <p>No derivatives yet</p>
    );
