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
                <th scope="col">Leverage</th>
                <th scope="col">Notional Amount</th>
                <th scope="col">Fee Liquidation Deposit Amount</th>
                <th scope="col">Fee Opening Amount</th>
                <th scope="col">Fee IPOR publication Amount</th>
                <th scope="col">Spread percentage</th>
                <th scope="col">IPOR Index Value</th>
                <th scope="col">Interest Bearing Token Price</th>
                <th scope="col">Interest Bearing Token Quantity</th>
                <th scope="col">Fixed Interest Rate</th>
                <th scope="col">SOAP</th>
                <th scope="col">Start Date</th>
                <th scope="col">End Date</th>

            </tr>
            </thead>
            <tbody>
            {derivatives.map(derivative => {
                    if (derivative.state == 0 ||derivative.state == 1) {
                        return (
                            <tr key={derivative.id}>
                                <td>{derivative.id}</td>
                                <td>{derivative.buyer}</td>
                                <td>{derivative.asset}</td>
                                <td>{derivative.direction}</td>
                                <td>{derivative.depositAmount}</td>
                                <td>{derivative.leverage}</td>
                                <td>{derivative.notionalAmount}</td>
                                <td>{derivative.fee.liquidationDepositAmount }</td>
                                <td>{derivative.fee.openingAmount }</td>
                                <td>{derivative.fee.iporPublicationAmount }</td>
                                <td>{derivative.fee.spreadPercentage }</td>
                                <td>{derivative.indicator.iporIndexValue }</td>
                                <td>{derivative.indicator.ibtPrice }</td>
                                <td>{derivative.indicator.ibtQuantity}</td>
                                <td>{derivative.indicator.fixedInterestRate}</td>
                                <td>{derivative.indicator.soap}</td>
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
