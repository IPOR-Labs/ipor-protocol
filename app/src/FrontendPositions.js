import React from "react";
import {toDate} from "./utils";
// import { Link } from "react-router-dom";

export default (derivatives) => (
    derivatives && derivatives.length > 0 ? (
        <div>
            <table className="table">
                <thead>
                <tr>
                    <th scope="col">id</th>
                    <th scope="col">Asset</th>
                    <th scope="col">Collateral</th>
                    <th scope="col">Notional Amount</th>
                    <th scope="col">Collateralization Factor</th>
                    <th scope="col">Direction</th>
                    <th scope="col">Fixed Interest Rate</th>
                    <th scope="col">Position Value</th>
                    <th scope="col">Starting Timestamp</th>
                    <th scope="col">Ending Timestamp</th>
                    <th scope="col">Liquidation Deposit Amount</th>
                </tr>
                </thead>
                <tbody>
                {derivatives.map(derivative => {
                        return (
                            <tr key={derivative.id}>
                                <td>{derivative.id}</td>
                                <td>{derivative.asset}</td>
                                <td>
                                    {derivative.collateral / 1000000000000000000}<br/><small>{derivative.collateral}</small>
                                </td>
                                <td>
                                    {derivative.notionalAmount / 1000000000000000000}<br/><small>{derivative.notionalAmount}</small>
                                </td>
                                <td>{derivative.collateralizationFactor}</td>
                                <td>{derivative.direction}</td>
                                <td>
                                    {derivative.fixedInterestRate / 1000000000000000000}
                                    <br/><small>{derivative.fixedInterestRate}</small>
                                </td>
                                <td>
                                    {derivative.positionValue / 1000000000000000000}
                                    <br/><small>{derivative.positionValue}</small>
                                </td>
                                <td>{toDate(derivative.startingTimestamp)}</td>
                                <td>{toDate(derivative.endingTimestamp)}</td>
                                <td>{derivative.liquidationDepositAmount}</td>
                            </tr>
                        )
                    }
                )}
                </tbody>
            </table>

        </div>
    ) : <p>No derivatives yet</p>
);
