// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");
const fs = require('fs');
const { ecsign } = require("ethereumjs-util");

const getTokenData = (filePath) => {
  try {
    const jsonString = fs.readFileSync(filePath);
    const data = JSON.parse(jsonString);
    return data;
  } catch (err) {
    console.log(err);
    return
  }
}

const getBigNumber = (amount, decimals = 18) => {
  return ethers.BigNumber.from(amount).mul(ethers.BigNumber.from(10).pow(decimals));
}

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Get token info into deploy script
  const mockTokenData = getTokenData("./contracts/mock/tokenMockData.json");
  const mockTokenDataLength = mockTokenData["tokens"].length;

  // Deploy tokens and keep references to the deployment
  let tokensObject = {};
  for (let i = 0; i < mockTokenDataLength; i++) {
    var currentToken = mockTokenData["tokens"][i]
    tokensObject[currentToken["symbol"]] = await deploy("ERC20Mock", {
      from: deployer,
      args: [
        currentToken["name"],
        currentToken["symbol"],
        getBigNumber(currentToken["supply"])
      ],
      deterministicDeployment: false,
    });
    console.log(`${currentToken['symbol']} address: `)
    console.log(tokensObject[currentToken["symbol"]]['address'])
  }

  // Pass native token to bentobox 
  var nativeToken = tokensObject["wFTM"]
  var { address } = await deploy("BentoBoxV1", {
    from: deployer,
    args: [nativeToken.address],
    deterministicDeployment: false,
  });

  // Transfer fBTC to localhost user
  var fBTC = tokensObject["fBTC"]
  const fBTCERC20Mock = await ethers.getContractFactory('ERC20Mock');
  const fBTCContract = await fBTCERC20Mock.attach(fBTC.address, deployer)
  await fBTCContract.transfer("0x11Fe47d9fC54BFCdE4f49970218C60605B7b5109", 1000000);

  console.log("BentoBoxV1 deployed at ", address);

  // Deploy HelloBentoBox
  var helloBentoBox = await deploy("HelloBentoBox", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [address],
    log: true,
  });
  console.log("HelloBentoBox deployed at ", helloBentoBox.address);

  // Enabling helloBentoBox for approval without signed messages on bento
  const BentoBoxV1 = await ethers.getContract("BentoBoxV1", deployer);
  await BentoBoxV1.whitelistMasterContract(helloBentoBox.address, true);

  console.log("helloBentoBox whitelisting enabled");

  // deployer giving helloBentoBox contract right to transfer funds on its behalf
  await whitelistBentoBox(
    deployer, 
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", 
    helloBentoBox, 
    BentoBoxV1
  );
  console.log("deployer has given helloBentoBox proxy rights");
  // await whitelistBentoBox(
  //   "0x11Fe47d9fC54BFCdE4f49970218C60605B7b5109", 
  //   "0xbff3671e5bd48f8b6d80af321530ae9ff947d19902de88c3dc39335e5fa5a9b5", 
  //   helloBentoBox, 
  //   BentoBoxV1
  // );
  // console.log("localuser has given helloBentoBox proxy rights");
  
  /*
    // Getting a previously deployed contract
    const YourContract = await ethers.getContract("YourContract", deployer);
    await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */
};
module.exports.tags = ["HelloBentoBox"];

async function whitelistBentoBox(userAddress, privateKey, helloBentoBox, BentoBoxV1) {
  const nonce = await BentoBoxV1.nonces(userAddress);
  const { v, r, s } = getSignedMasterContractApprovalData(
    BentoBoxV1,
    userAddress,
    privateKey,
    helloBentoBox.address,
    true,
    nonce
  )
  const HelloBentoBox = await ethers.getContract("HelloBentoBox", userAddress);
  await HelloBentoBox.setBentoBoxApproval(
    userAddress,
    true,
    v,
    r,
    s
  );
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
  const msg = ethers.utils.defaultAbiCoder.encode(
    ["bytes32", "bytes32", "address", "address", "bool", "uint256"],
    [
      BENTOBOX_MASTER_APPROVAL_TYPEHASH,
      approved
        ? ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes(
              "Give FULL access to funds in (and approved to) BentoBox?"
            )
          )
        : ethers.utils.keccak256(ethers.utils.toUtf8Bytes("Revoke access to BentoBox?")),
      user,
      masterContractAddress,
      approved,
      nonce,
    ]
  );
  const pack = ethers.utils.solidityPack(
    ["bytes1", "bytes1", "bytes32", "bytes32"],
    ["0x19", "0x01", DOMAIN_SEPARATOR, ethers.utils.keccak256(msg)]
  );
  return ethers.utils.keccak256(pack);
}

function getBentoBoxDomainSeparator(address, chainId) {
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "bytes32", "uint256", "address"],
      [
        ethers.utils.keccak256(
          ethers.utils.toUtf8Bytes(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
          )
        ),
        ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BentoBox V1")),
        chainId,
        address,
      ]
    )
  );
}

const BENTOBOX_MASTER_APPROVAL_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes(
    "SetMasterContractApproval(string warning,address user,address masterContract,bool approved,uint256 nonce)"
  )
);

// TODO: create accounts with tokens in them
//    - first try to use bento directly
//    - then try to use helloBentoBox as a proxy
// TODO: See how other contracts deal with bento deployments