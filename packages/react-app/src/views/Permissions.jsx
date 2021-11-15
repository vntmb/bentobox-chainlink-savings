import { ethers, utils } from "ethers";
import { ecsign } from "ethereumjs-util";
import { useContractExistsAtAddress, useContractLoader } from "eth-hooks";
import { Select } from "antd";
import React, { useState } from "react";
import { Address, AddressInput } from "../components";
import { Button, Card } from "antd";
import { useTokenList } from "eth-hooks/dapps/dex";

const { Option } = Select;
const TokenArtifacts = require('../contracts/hardhat_contracts.json');

export default function Permissions({ localChainId, userSigner, address }) {
    // Get a list of tokens from a tokenlist -> see tokenlists.org!
    const [selectedToken, setSelectedToken] = useState("Pick a token!");
    const listOfTokens = useTokenList(
        "https://raw.githubusercontent.com/SetProtocol/uniswap-tokenlist/main/set.tokenlist.json",
    );
    localChainId = localChainId == null ? 31337 : localChainId
    const helloBentoBoxAbi = TokenArtifacts[localChainId]["localhost"]["contracts"]["HelloBentoBox"].abi;
    const bentoBoxV1Abi = TokenArtifacts[localChainId]["localhost"]["contracts"]["BentoBoxV1"].abi;

    const helloBentoBoxAddress = "0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1";
    const bentoBoxV1Address = "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d";
    const handleClick = async () => {
        const HelloBentoBox = new ethers.Contract(helloBentoBoxAddress, helloBentoBoxAbi, userSigner);
        
        const BentoBoxV1 = new ethers.Contract(bentoBoxV1Address, bentoBoxV1Abi, userSigner);
        var result = await whitelistBentoBox(
            address, 
            "0xbff3671e5bd48f8b6d80af321530ae9ff947d19902de88c3dc39335e5fa5a9b5",
            HelloBentoBox,
            BentoBoxV1
        );

        var res = await HelloBentoBox.depositToHelloBentoBox(
            "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853",
            100,
            false
        );
    };

    return (
        <div>
            <div style={{ width: 600, margin: "auto", marginTop: 32, paddingBottom: 256 }}>
                <Card style={{ marginTop: 32 }}>
                    <div>
                        There are tons of generic components included from{" "}
                        <a href="https://ant.design/components/overview/" target="_blank" rel="noopener noreferrer">
                            🐜 ant.design
                        </a>{" "}
                        too!
                    </div>
                    <div style={{ marginTop: 8 }}>
                        <Button type="primary" onClick={handleClick}>Give Permissions</Button>
                    </div>
                </Card>
            </div>
        </div>
    );
}

async function whitelistBentoBox(userAddress, privateKey, HelloBentoBox, BentoBoxV1) {
    const nonce = await BentoBoxV1.nonces(userAddress);
    const { v, r, s } = getSignedMasterContractApprovalData(
        BentoBoxV1,
        userAddress,
        privateKey,
        HelloBentoBox.address,
        true,
        nonce
    )
    
    await HelloBentoBox.setBentoBoxApproval(
        userAddress,
        true,
        v,
        r,
        s
    );
    return "success";
}


function getSignedMasterContractApprovalData(
    bentoBox,
    user,
    privateKey,
    masterContractAddress,
    approved,
    nonce
) {
    const digest = getBentoBoxApprovalDigest(
        bentoBox,
        user,
        masterContractAddress,
        approved,
        nonce,
        31337
    );
    const { v, r, s } = ecsign(
        Buffer.from(digest.slice(2), "hex"),
        Buffer.from(privateKey.replace("0x", ""), "hex")
    );
    return { v, r, s };
}


function getBentoBoxApprovalDigest(
    bentoBox,
    user,
    masterContractAddress,
    approved,
    nonce,
    chainId = 1
) {
    const DOMAIN_SEPARATOR = getBentoBoxDomainSeparator(
        bentoBox.address,
        chainId
    );
    const msg = utils.defaultAbiCoder.encode(
        ["bytes32", "bytes32", "address", "address", "bool", "uint256"],
        [
            BENTOBOX_MASTER_APPROVAL_TYPEHASH,
            approved
                ? utils.keccak256(
                    utils.toUtf8Bytes(
                        "Give FULL access to funds in (and approved to) BentoBox?"
                    )
                )
                : utils.keccak256(utils.toUtf8Bytes("Revoke access to BentoBox?")),
            user,
            masterContractAddress,
            approved,
            nonce,
        ]
    );
    const pack = utils.solidityPack(
        ["bytes1", "bytes1", "bytes32", "bytes32"],
        ["0x19", "0x01", DOMAIN_SEPARATOR, utils.keccak256(msg)]
    );
    return utils.keccak256(pack);
}

function getBentoBoxDomainSeparator(address, chainId) {
    return utils.keccak256(
        utils.defaultAbiCoder.encode(
            ["bytes32", "bytes32", "uint256", "address"],
            [
                utils.keccak256(
                    utils.toUtf8Bytes(
                        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
                    )
                ),
                utils.keccak256(utils.toUtf8Bytes("BentoBox V1")),
                chainId,
                address,
            ]
        )
    );
}

const BENTOBOX_MASTER_APPROVAL_TYPEHASH = utils.keccak256(
    utils.toUtf8Bytes(
        "SetMasterContractApproval(string warning,address user,address masterContract,bool approved,uint256 nonce)"
    )
);
