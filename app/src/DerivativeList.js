import React from "react";
import {toDate} from "./utils";
// import { Link } from "react-router-dom";

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
                <th scope="col">Collateralization Factor</th>
                <th scope="col">Notional Amount</th>
                <th scope="col">Fee Liquidation Deposit Amount</th>
                <th scope="col">Fee Opening Amount</th>
                <th scope="col">Fee IPOR publication Amount</th>
                <th scope="col">Spread percentage</th>
                <th scope="col">IPOR Index Value</th>
                <th scope="col">Interest Bearing Token Price</th>
                <th scope="col">Interest Bearing Token Quantity</th>
                <th scope="col">Fixed Interest Rate</th>
                <th scope="col">Start Date</th>
                <th scope="col">End Date</th>

            </tr>
            </thead>
            <tbody>
            {derivatives.map(derivative => {
                    if (derivative.state == 1) {
                        return (
                            <tr key={derivative.id}>
                                <td>{derivative.id}</td>
                                <td>{derivative.buyer}</td>
                                <td>{derivative.asset}</td>
                                <td>{derivative.direction}</td>
                                <td>{derivative.collateral / derivative.multiplicator}<br/><small>{derivative.collateral}</small>
                                </td>
                                <td>
                                    {derivative.collateralizationFactor}
                                </td>
                                <td>
                                    {derivative.notionalAmount / derivative.multiplicator}
                                    <br/><small>{derivative.notionalAmount}</small>
                                </td>
                                <td>
                                    {derivative.fee.liquidationDepositAmount / derivative.multiplicator}
                                    <br/><small>{derivative.fee.liquidationDepositAmount}</small>
                                </td>
                                <td>
                                    {derivative.fee.openingAmount / derivative.multiplicator}
                                    <br/><small>{derivative.fee.openingAmount}</small>
                                </td>
                                <td>
                                    {derivative.fee.iporPublicationAmount / derivative.multiplicator}
                                    <br/><small>{derivative.fee.iporPublicationAmount}</small>
                                </td>
                                <td>
                                    {derivative.fee.spreadPercentage / derivative.multiplicator}
                                    <br/><small>{derivative.fee.spreadPercentage}</small>
                                </td>
                                <td>
                                    {derivative.indicator.iporIndexValue / derivative.multiplicator}
                                    <br/><small>{derivative.indicator.iporIndexValue}</small>
                                </td>
                                <td>
                                    {derivative.indicator.ibtPrice / derivative.multiplicator}
                                    <br/><small>{derivative.indicator.ibtPrice}</small></td>
                                <td>
                                    {derivative.indicator.ibtQuantity / derivative.multiplicator}
                                    <br/><small>{derivative.indicator.ibtQuantity}</small>
                                </td>
                                <td>
                                    {derivative.indicator.fixedInterestRate / derivative.multiplicator}
                                    <br/><small>{derivative.indicator.fixedInterestRate}</small>
                                </td>
                                <td>{toDate(derivative.startingTimestamp)}</td>
                                <td>{toDate(derivative.endingTimestamp)}</td>
                            </tr>
                        )
                    }
                }
            )}
            </tbody>
        </table>
    ) : <p>No derivatives yet</p>
);
