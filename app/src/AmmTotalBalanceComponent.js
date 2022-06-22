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
            </tr>
            <tr>
                <td>
                    <strong>
                        {process.env.REACT_APP_ITF_ENABLED === "true"
                            ? "ITF Milton Total Balance"
                            : "Milton Total Balance"}
                    </strong>
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.ItfMiltonUsdt.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdt"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MiltonUsdt.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.ItfMiltonUsdc.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleUsdc"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MiltonUsdc.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
                </td>
                <td>
                    {process.env.REACT_APP_ITF_ENABLED === "true" ? (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.ItfMiltonDai.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    ) : (
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleDai"
                            method="balanceOf"
                            methodArgs={[drizzle.contracts.MiltonDai.address]}
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    )}
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
            </tr>
            <tr>
                <td>
                    <strong>
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? "ITF Milton" : "Milton"}
                    </strong>
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
            </tr>
            <tr>
                <td></td>
                <td>
                    <strong>Milton</strong>{" "}
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdt.address
                        : drizzle.contracts.MiltonUsdt.address}
                    <br />
                    <ContractForm drizzle={drizzle} contract="DrizzleUsdt" method="approve" />
                </td>
                <td>
                    <strong>Milton</strong>{" "}
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonUsdc.address
                        : drizzle.contracts.MiltonUsdc.address}
                    <br />
                    <ContractForm drizzle={drizzle} contract="DrizzleUsdc" method="approve" />
                </td>
                <td>
                    <strong>Milton</strong>{" "}
                    {process.env.REACT_APP_ITF_ENABLED === "true"
                        ? drizzle.contracts.ItfMiltonDai.address
                        : drizzle.contracts.MiltonDai.address}
                    <br />
                    <ContractForm drizzle={drizzle} contract="DrizzleDai" method="approve" />
                </td>
            </tr>
        </table>

        <hr />
    </div>
);
