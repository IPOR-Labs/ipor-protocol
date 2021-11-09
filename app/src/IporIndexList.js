import React from "react";
// import { Link } from "react-router-dom";
import {toDate} from "./utils.js";

export default (indexes) => (
    indexes && indexes.length > 0 ? (
        <table className="table">
            <thead>
            <tr>
                <th scope="col">Asset</th>
                <th scope="col">IPOR Value</th>
                <th scope="col">Interest Bearing Token Price</th>
                <th scope="col">Block Timestamp</th>
            </tr>
            </thead>
            <tbody>
            {indexes.map(index => (
                <tr key={index.asset}>
                    <td>{index.asset}</td>
                    <td>
                        {index.asset === "DAI" ? index.indexValue / 1000000000000000000 : index.indexValue / 1000000}
                        <br/>
                        <small>{index.indexValue}</small>
                    </td>
                    <td>
                        {index.asset === "DAI" ? index.ibtPrice  / 1000000000000000000 : index.ibtPrice  / 1000000}
                        <br/>
                        <small>{index.ibtPrice}</small>
                    </td>
                    <td>{toDate(index.blockTimestamp)}</td>
                </tr>
            ))}
            </tbody>
        </table>
    ) : <p>No IPOR Indexes yet</p>
);
