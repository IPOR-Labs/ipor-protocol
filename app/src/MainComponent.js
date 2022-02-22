import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import logo from "./logo.png";
import { Container, Navbar, Tabs } from "react-bootstrap";
import { Tab } from "bootstrap";
import IporIndexComponent from "./WarrenComponent";
import MiltonComponent from "./MiltonComponent";
import MyPositions from "./MyPositions";
import IporAssetConfigurationComponent from "./IporAssetConfigurationComponent";
import MiltonConfigurationComponent from "./MiltonConfigurationComponent";
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
                        IPOR Protocol - MILTON Dev Tool
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
                        <td>{drizzle.contracts.UsdtMockedToken.address}</td>
                        <td>{drizzle.contracts.UsdcMockedToken.address}</td>
                        <td>{drizzle.contracts.DaiMockedToken.address}</td>
                    </tr>
                </table>
            </div>
            <Tabs defaultActiveKey="profile" id="uncontrolled-tab-example">
                <Tab eventKey="iporIndex" title="Warren Oracle">
                    <IporIndexComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="miltonOverview" title="Milton Overview">
                    <MiltonComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>				
                <Tab eventKey="globalConfig" title="Global Configuration">
                    <GlobalConfigurationComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
				<Tab eventKey="miltonConfig" title="Milton Configuration">
                    <MiltonConfigurationComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="assetConfig" title="Asset Configuration">
                    <IporAssetConfigurationComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="spreadConfig" title="Spread Configuration">
                    <MiltonSpreadConfigurationComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="myPositions" title="My positions">
                    <MyPositions
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="faucet" title="Faucet">
                    <FaucetComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
                <Tab eventKey="frontend" title="Frontend Data Provider">
                    <FrontendComponent
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                    />
                </Tab>
            </Tabs>
        </div>
    );
};
