import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Pause</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StanleyUsdt"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StanleyUsdc"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StanleyDai"
                                method="pause"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Unpause</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StanleyUsdt"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StanleyUsdc"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StanleyDai"
                                method="unpause"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h2>Strategies claim</h2>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdt"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                        <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdc"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                        <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveDai"
                                method="doClaim"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Compound</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdt"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                        <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdc"
                                method="doClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                        <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundDai"
                                method="doClaim"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h2>Strategies claim</h2>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdt"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                    {/* <td>
                        <div>
                        <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdc"
                                method="beforeClaim"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                        <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveDai"
                                method="beforeClaim"
                            />
                        </div>
                    </td> */}
                </tr>
            </table>
        </div>
    </div>
);
