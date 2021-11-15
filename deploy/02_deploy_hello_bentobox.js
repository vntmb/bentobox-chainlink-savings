// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");
const fs = require('fs');

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

  // Deploy tokens and add keep references to the deployment
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
  }

  // Pass native token to bentobox 
  var nativeToken = tokensObject["wFTM"]
  const { address } = await deploy("BentoBoxV1", {
    from: deployer,
    args: [nativeToken.address],
    deterministicDeployment: false,
  });

  console.log("BentoBoxV1 deployed at ", address);

  // Deploy HelloBentoBox
  await deploy("HelloBentoBox", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [address],
    log: true,
  });

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
