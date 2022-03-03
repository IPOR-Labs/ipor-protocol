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

                {/* <tr>
                    <td>Transfer Ownership</td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdt"
                            method="transferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdc"
                            method="transferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyDai"
                            method="transferOwnership"
                        />
                    </td>
                </tr>

                <tr>
                    <td>Confirm Transfer Ownership</td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdt"
                            method="confirmTransferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyUsdc"
                            method="confirmTransferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="StanleyDai"
                            method="confirmTransferOwnership"
                        />
                    </td>
                </tr> */}
            </table>
        </div>
    </div>
);
