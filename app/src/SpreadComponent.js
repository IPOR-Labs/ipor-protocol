import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <table className="table" align="center">
            <tr>
                <th scope="col">SPREAD</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>SPREAD Pay Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDT"]}
                        render={(item) => (
                            <div>
                                {item.spreadPf / 1000000000000000000}<br/>
                                <small>{item.spreadPf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDC"]}
                        render={(item) => (
                            <div>
                                {item.spreadPf / 1000000000000000000}<br/>
                                <small>{item.spreadPf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["DAI"]}
                        render={(item) => (
                            <div>
                                {item.spreadPf / 1000000000000000000}<br/>
                                <small>{item.spreadPf}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>SPREAD Receive Fixed</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDT"]}
                        render={(item) => (
                            <div>
                                {item.spreadRf / 1000000000000000000}<br/>
                                <small>{item.spreadRf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["USDC"]}
                        render={(item) => (
                            <div>
                                {item.spreadRf / 1000000000000000000}<br/>
                                <small>{item.spreadRf}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="calculateSpread"
                        methodArgs={["DAI"]}
                        render={(item) => (
                            <div>
                                {item.spreadRf / 1000000000000000000}<br/>
                                <small>{item.spreadRf}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
    </div>
);