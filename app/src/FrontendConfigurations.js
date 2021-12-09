import React from "react";
// import { Link } from "react-router-dom";

export default (configurations) =>
    configurations && configurations.length > 0 ? (
        <div>
            <table className="table">
                <thead>
                    <tr>
                        <th scope="col">Asset</th>
                        <th scope="col">Min Collateralization Factor Value</th>
                        <th scope="col">Max Collateralization Factor Value</th>
                        <th scope="col">Opening Fee Percentage</th>
                        <th scope="col">IPOR Publication Fee Amount</th>
                        <th scope="col">Liquidation Deposit Amount</th>
                        <th scope="col">Income Tax Percentage</th>
                        <th scope="col">Spread Pay Fixed Value</th>
                        <th scope="col">Spread Receive Fixed Value</th>
                    </tr>
                </thead>
                <tbody>
                    {configurations.map((configuration) => {
                        return (
                            <tr key={configuration.asset}>
                                <td>{configuration.asset}</td>
                                <td>
                                    {configuration.minCollateralizationFactorValue /
                                        1000000000000000000}
                                    <br />
                                    <small>
                                        {
                                            configuration.minCollateralizationFactorValue
                                        }
                                    </small>
                                </td>
                                <td>
                                    {configuration.maxCollateralizationFactorValue /
                                        1000000000000000000}
                                    <br />
                                    <small>
                                        {
                                            configuration.maxCollateralizationFactorValue
                                        }
                                    </small>
                                </td>
                                <td>
                                    {configuration.openingFeePercentage /
                                        1000000000000000000}
                                    <br />
                                    <small>
                                        {configuration.openingFeePercentage}
                                    </small>
                                </td>
                                <td>
                                    {configuration.iporPublicationFeeAmount /
                                        1000000000000000000}
                                    <br />
                                    <small>
                                        {configuration.iporPublicationFeeAmount}
                                    </small>
                                </td>
                                <td>
                                    {configuration.liquidationDepositAmount/
                                            1000000000000000000}
                                    <br />
                                    <small>
                                        {configuration.liquidationDepositAmount}
                                    </small>
                                </td>
                                <td>
                                    {configuration.incomeTaxPercentage/
                                            1000000000000000000}
                                    <br />
                                    <small>
                                        {configuration.incomeTaxPercentage}
                                    </small>
                                </td>
                                <td>
                                    {configuration.spreadPayFixedValue/
                                            1000000000000000000}
                                    <br />
                                    <small>
                                        {configuration.spreadPayFixedValue}
                                    </small>
                                </td>
                                <td>
                                    {configuration.spreadRecFixedValue/
                                            1000000000000000000}
                                    <br />
                                    <small>
                                        {configuration.spreadRecFixedValue}
                                    </small>
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
