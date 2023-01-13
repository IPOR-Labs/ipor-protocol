import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import logo from "./logo.png";
import { Container, Navbar, Tabs } from "react-bootstrap";
import { Tab } from "bootstrap";
import IporOracleComponent from "./IporOracleComponent";
import MiltonComponent from "./MiltonComponent";
import JosephComponent from "./JosephComponent";
import StanleyComponent from "./StanleyComponent";
import MyPositions from "./MyPositions";
import JosephConfigurationComponent from "./JosephConfigurationComponent";
import MiltonConfigurationComponent from "./MiltonConfigurationComponent";
import StanleyConfigurationComponent from "./StanleyConfigurationComponent";
import MiltonSpreadConfigurationComponent from "./MiltonSpreadConfigurationComponent";
import GlobalConfigurationComponent from "./GlobalConfigurationComponent";
import FaucetComponent from "./FaucetComponent";
import FrontendComponent from "./FrontendComponent";

require("dotenv").config({ path: "../../.env" });
const { AccountData, ContractData, ContractForm } = newContextComponents;


export default ({ drizzle, drizzleState }) => {
    return (
        <div className="App">
            <Container>
                <Navbar fixed="top" bg="dark" variant="dark">
                    <Navbar.Brand href="#home">
                        <img
                            alt=""
                            src={logo}
                            width="30"
                            height="30"
                            className="d-inline-block align-top ipor-navbar"
                        />{" "}
                        IPOR Protocol - Cockpit{" "}
                        {process.env.REACT_APP_ITF_ENABLED === "true" ? "- [ ITF ENABLED ]" : ""}
                    </Navbar.Brand>
                </Navbar>
            </Container>

            <div className="section">
                <p>Active Account</p>
                <AccountData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    accountIndex={0}
                    units="ether"
                    precision={3}
                />
            </div>
            <div>
                <table className="table" align="center">
                    <tr>
                        <th scope="col"></th>
                        <th scope="col">USDT</th>
                        <th scope="col">USDC</th>
                        <th scope="col">DAI</th>
                    </tr>
                    <tr>
                        <td>
                            <strong>ERC20 Token Address</strong>
                        </td>
                        <td>{drizzle.contracts.DrizzleUsdt.address}</td>
                        <td>{drizzle.contracts.DrizzleUsdc.address}</td>
                        <td>{drizzle.contracts.DrizzleDai.address}</td>
                    </tr>
                </table>
            </div>
            <Tabs defaultActiveKey="profile" id="uncontrolled-tab-example">
                <Tab eventKey="iporIndex" title="IporOracle">
                    <IporOracleComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>

                 <Tab eventKey="miltonOverview" title="Milton">
                    <MiltonComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>

                <Tab eventKey="joseph" title="Joseph">
                    <JosephComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>
                <Tab eventKey="stanley" title="Stanley">
                    <StanleyComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>
                <Tab eventKey="globalConfig" title="Global Config">
                    <GlobalConfigurationComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>
                <Tab eventKey="josephConfig" title="Joseph Config">
                    <JosephConfigurationComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>
                <Tab eventKey="miltonConfig" title="Milton Config">
                    <MiltonConfigurationComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>
                <Tab eventKey="spreadConfig" title="Spread Config">
                    <MiltonSpreadConfigurationComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="stanleyConfig" title="Stanley Config">
                    <StanleyConfigurationComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>
                <Tab eventKey="myPositions" title="My positions">
                    <MyPositions drizzle={drizzle} drizzleState={drizzleState} />
                </Tab>

                {process.env.REACT_APP_ENV_PROFILE !== "mainnet.ipor.io" ? (
                    <Tab eventKey="faucet" title="Faucet">
                        <FaucetComponent drizzle={drizzle} drizzleState={drizzleState} />
                    </Tab>
                ) : (
                    ""
                )}

                <Tab eventKey="frontend" title="Frontend Data Provider">
                    <FrontendComponent drizzle={drizzle} drizzleState={drizzleState} />
                </Tab> 
            </Tabs>
        </div>
    );
};
