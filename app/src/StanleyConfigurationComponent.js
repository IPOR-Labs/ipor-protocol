import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <h4>Stanley: Setup new Milton address</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyUsdt"
                                method="getMilton"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdt"
                                method="setMilton"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyUsdc"
                                method="getMilton"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdc"
                                method="setMilton"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyDai"
                                method="getMilton"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyDai"
                                method="setMilton"
                            />
                        </div>
                    </td>
                </tr>
            </table>

            <h4>Stanley: Setup new Strategy address</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>AAVE</strong>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyUsdt"
                                method="getStrategyAave"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdt"
                                method="setStrategyAave"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyUsdc"
                                method="getStrategyAave"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdc"
                                method="setStrategyAave"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyDai"
                                method="getStrategyAave"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyDai"
                                method="setStrategyAave"
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
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyUsdt"
                                method="getStrategyCompound"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdt"
                                method="setStrategyCompound"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyUsdc"
                                method="getStrategyCompound"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyUsdc"
                                method="setStrategyCompound"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleStanleyDai"
                                method="getStrategyCompound"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleStanleyDai"
                                method="setStrategyCompound"
                            />
                        </div>
                    </td>
                </tr>
            </table>

            <h4>Strategies: Setup new Stanley address</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>AAVE</strong>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveUsdt"
                                method="getStanley"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdt"
                                method="setStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveUsdc"
                                method="getStanley"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdc"
                                method="setStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveDai"
                                method="getStanley"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveDai"
                                method="setStanley"
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
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundUsdt"
                                method="getStanley"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdt"
                                method="setStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundUsdc"
                                method="getStanley"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdc"
                                method="setStanley"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundDai"
                                method="getStanley"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundDai"
                                method="setStanley"
                            />
                        </div>
                    </td>
                </tr>
            </table>

            <h4>Strategies: Setup new Treasury Manager address</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveUsdt"
                                method="getTreasuryManager"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveUsdc"
                                method="getTreasuryManager"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveDai"
                                method="getTreasuryManager"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveDai"
                                method="setTreasuryManager"
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
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundUsdt"
                                method="getTreasuryManager"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundUsdc"
                                method="getTreasuryManager"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundDai"
                                method="getTreasuryManager"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundDai"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>
            </table>
            <h4>Strategies: Setup new Treasury address</h4>
            <table className="table" align="center">
                <tr>
                    <th scope="col">Strategy</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>

                <tr>
                    <td>
                        <strong>Aave</strong>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveUsdt"
                                method="getTreasury"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveUsdc"
                                method="getTreasury"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyAaveDai"
                                method="getTreasury"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyAaveDai"
                                method="setTreasury"
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
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundUsdt"
                                method="getTreasury"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundUsdc"
                                method="getTreasury"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="StrategyCompoundDai"
                                method="getTreasury"
                            />
                        </div>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="StrategyCompoundDai"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
