import React from "react";
// import { Link } from "react-router-dom";

export default (configurations) =>
    configurations && configurations.length > 0 ? (
        <div>
            <table className="table">
                <thead>
                    <tr>
                        <th scope="col">Asset</th>
                        <th scope="col">Min Leverage Value</th>
                        <th scope="col">Max Leverage Value</th>
                        <th scope="col">Opening Fee Percentage</th>
                        <th scope="col">IPOR Publication Fee Amount</th>
                        <th scope="col">Liquidation Deposit Amount</th>
                        <th scope="col">Income Fee Percentage</th>
                        <th scope="col">Max Liquidity Pool Utilization Percentage</th>
                        <th scope="col">Max Liquidity Pool Utilization Per Leg Percentage</th>
                    </tr>
                </thead>
                <tbody>
                    {configurations.map((configuration) => {
                        return (
                            <tr key={configuration.asset}>
                                <td>{configuration.asset}</td>
                                <td>
                                    {configuration.minLeverageValue / 1000000000000000000}
                                    <br />
                                    <small>{configuration.minLeverageValue}</small>
                                </td>
                                <td>
                                    {configuration.maxLeverageValue / 1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLeverageValue}</small>
                                </td>
                                <td>
                                    {configuration.openingFeePercentage / 1000000000000000000}
                                    <br />
                                    <small>{configuration.openingFeePercentage}</small>
                                </td>
                                <td>
                                    {configuration.iporPublicationFeeAmount / 1000000000000000000}
                                    <br />
                                    <small>{configuration.iporPublicationFeeAmount}</small>
                                </td>
                                <td>
                                    {configuration.liquidationDepositAmount / 1000000000000000000}
                                    <br />
                                    <small>{configuration.liquidationDepositAmount}</small>
                                </td>
                                <td>
                                    {configuration.incomeFeePercentage / 1000000000000000000}
                                    <br />
                                    <small>{configuration.incomeFeePercentage}</small>
                                </td>
                                <td>
                                    {configuration.maxLpUtilizationPercentage / 1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLpUtilizationPercentage}</small>
                                </td>
                                <td>
                                    {configuration.maxLpUtilizationPerLegPercentage /
                                        1000000000000000000}
                                    <br />
                                    <small>{configuration.maxLpUtilizationPerLegPercentage}</small>
                                </td>
                            </tr>
                        );
                    })}
                </tbody>
            </table>
        </div>
    ) : (
        <p>No configuration set</p>
    );
