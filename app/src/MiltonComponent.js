import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import AmmBalanceComponent from "./AmmBalanceComponent";
import AmmTotalBalanceComponent from "./AmmTotalBalanceComponent";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div>
            <br />
            <AmmTotalBalanceComponent drizzle={drizzle} drizzleState={drizzleState} />
            <AmmBalanceComponent drizzle={drizzle} drizzleState={drizzleState} />
        </div>
        <hr />
        <table className="table" align="center">
            <tr>
                <th scope="col">Action</th>
                <th scope="col">
                    USDT
                    <br />
                    {drizzle.contracts.DrizzleUsdt.address}
                    <br />
                    <br />
                </th>
                <th scope="col">
                    USDC
                    <br />
                    {drizzle.contracts.DrizzleUsdc.address}
                    <br />
                    <br />
                </th>
                <th scope="col">
                    DAI
                    <br />
                    {drizzle.contracts.DrizzleDai.address}
                    <br />
                    <br />
                </th>
            </tr>
            <tr>
                <td>Open Pay Fixed Swap</td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdt"
                        method="openSwapPayFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdc"
                        method="openSwapPayFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonDai"
                        method="openSwapPayFixed"
                    />
                </td>
            </tr>
            <tr>
                <td>Open Receive Fixed Swap</td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdt"
                        method="openSwapReceiveFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdc"
                        method="openSwapReceiveFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonDai"
                        method="openSwapReceiveFixed"
                    />
                </td>
            </tr>
            <tr>
                <td>Close Pay Fixed Swap</td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdt"
                        method="closeSwapPayFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdc"
                        method="closeSwapPayFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonDai"
                        method="closeSwapPayFixed"
                    />
                </td>
            </tr>
            <tr>
                <td>Close Receive Fixed Swap</td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdt"
                        method="closeSwapReceiveFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonUsdc"
                        method="closeSwapReceiveFixed"
                    />
                </td>
                <td>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DrizzleMiltonDai"
                        method="closeSwapReceiveFixed"
                    />
                </td>
            </tr>
        </table>
    </div>
);
