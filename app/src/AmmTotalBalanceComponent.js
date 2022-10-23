import React from "react";
import { newContextComponents } from "@drizzle/react-components";
const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
                <th scope="col">WETH</th>
            </tr>
            <tr>
                <td>
                    <strong>Milton Total Balance</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleUsdt"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleMiltonUsdt.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleUsdc"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleMiltonUsdc.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleDai"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleMiltonDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="DrizzleWeth"
                        method="balanceOf"
                        methodArgs={[drizzle.contracts.DrizzleMiltonDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>My Total Balance</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleUsdt.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleUsdc.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td> <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={[drizzle.contracts.DrizzleWeth.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr />
        <table className="table" align="center">
            <tr>
                <th scope="col">My allowances</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
                <th scope="col">Weth</th>
            </tr>
            <tr>
                <td>
                    <strong>Milton</strong>
                    <br />
                    For opening and closing swap
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyAllowanceInMilton"
                        methodArgs={[drizzle.contracts.DrizzleUsdt.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyAllowanceInMilton"
                        methodArgs={[drizzle.contracts.DrizzleUsdc.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyAllowanceInMilton"
                        methodArgs={[drizzle.contracts.DrizzleDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="CockpitDataProvider"
                        method="getMyAllowanceInMilton"
                        methodArgs={[drizzle.contracts.DrizzleWeth.address]}
                        render={(value) => {
                            return (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}}
                    />
                </td>
            </tr>
            <tr>
                <td></td>
                <td>
                    <strong>Milton</strong> <small>{drizzle.contracts.DrizzleMiltonUsdt.address}</small>
                    <br />
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleUsdt"
                        method="approve"
                    />
                </td>
                <td>
                    <strong>Milton</strong> <small>{drizzle.contracts.DrizzleMiltonUsdc.address}</small>
                    <br />
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleUsdc"
                        method="approve"
                        
                    />
                </td>
                <td>
                    <strong>Milton</strong> <small>{drizzle.contracts.DrizzleMiltonDai.address}></small>
                    <br />
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleDai"
                        method="approve"
                    />
                </td>
                <td>
                    <strong>Milton</strong> <small>{drizzle.contracts.DrizzleMiltonWeth.address}</small>
                    <br />
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleWeth"
                        method="approve"
                    />
                </td>
            </tr>
        </table>

        <hr />
    </div>
);
