import React, {Component} from "react";
import {newContextComponents} from "@drizzle/react-components";

const { ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">ETH</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td><strong>Available Faucet balance</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={["ETH"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFaucet"
                        method="balanceOf"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td><strong>My Total Balance</strong></td>
                <td>
                    Check your wallet :)
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <div className="row">
            <div className="col-md-6">
                <strong>Transfer ETH to specific address</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonFaucet"
                    method="transferEth"
                />
            </div>
            <div className="col-md-6">
                <strong>Transfer TOKENS to your wallet</strong>
                <br/>
                <label>Max allowed value 1 000 000 USD</label>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonFaucet"
                    method="transfer"
                />
            </div>

        </div>


    </div>
);