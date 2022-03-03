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
                                contract="JosephUsdt"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdc"
                                method="pause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephDai"
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
                                contract="JosephUsdt"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephUsdc"
                                method="unpause"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="JosephDai"
                                method="unpause"
                            />
                        </div>
                    </td>
                </tr>
                <tr>
                    <td>Transfer Ownership</td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdt"
                            method="transferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdc"
                            method="transferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephDai"
                            method="transferOwnership"
                        />
                    </td>
                </tr>

                <tr>
                    <td>Confirm Transfer Ownership</td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdt"
                            method="confirmTransferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephUsdc"
                            method="confirmTransferOwnership"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="JosephDai"
                            method="confirmTransferOwnership"
                        />
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
