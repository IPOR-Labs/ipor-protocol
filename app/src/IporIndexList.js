import React from "react";
// import { Link } from "react-router-dom";
import { toDate } from "./utils.js";

export default (indexes) =>
    indexes && indexes.length > 0 ? (
        <table className="table">
            <thead>
                <tr>
                    <th scope="col">Asset</th>
                    <th scope="col">IPOR Value</th>
                    <th scope="col">Interest Bearing Token Price</th>
                    <th scope="col">Exponential Moving Average</th>
                    <th scope="col">Exponential Weighted Moving Variance</th>
                    <th scope="col">Last Update Timestamp</th>
                </tr>
            </thead>
            <tbody>
                {indexes.map((index) => (
                    <tr key={index.asset}>
                        <td>{index.asset}</td>
                        <td>
                            {index.indexValue / 1000000000000000000}

                            <br />
                            <small>{index.indexValue}</small>
                        </td>
                        <td>
                            {index.ibtPrice / 1000000000000000000}
                            <br />
                            <small>{index.ibtPrice}</small>
                        </td>
                        <td>
                            {index.exponentialMovingAverage / 1000000000000000000}
                            <br />
                            <small>{index.exponentialMovingAverage}</small>
                        </td>
                        <td>
                            {index.exponentialWeightedMovingVariance / 1000000000000000000}
                            <br />
                            <small>{index.exponentialWeightedMovingVariance}</small>
                        </td>
                        <td>
							{toDate(index.lastUpdateTimestamp)}
							<br/>
							<small>{index.lastUpdateTimestamp}</small>
						</td>
                    </tr>
                ))}
            </tbody>
        </table>
    ) : (
        <p>No IPOR Indexes yet</p>
    );
