const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  // deploy the NFT contract 
  const nftContract = await hre.ethers.deployContract("CryptoDevsNFT");
  await nftContract.waitForDeployment();
  console.log("CryptoDevsNFT deployed to: ", nftContract.target);

  // deploy the Fake Marketplace contract
  const fakeNftMarketplaceContract = await hre.ethers.deployContract("FakeNFTMarketplace");
  await fakeNftMarketplaceContract.waitForDeployment();
  console.log("FakeNftMarketplace deployed to: ", fakeNftMarketplaceContract.target);

  // deploy the DAO contract
  const daoContract = await hre.ethers.deployContract("CryptoDevsDAO",[
    fakeNftMarketplaceContract.target,
    nftContract.target,
  ]);
  await daoContract.waitForDeployment();
  console.log("DAO contract deployed at: ", daoContract.target);

  // sleep for 30 seconds to let etherscan catch up with the deployments
  await sleep(30 * 1000);

  // verify the NFT contract
  await hre.run("verify:verify", {
    address: nftContract.target,
    constructorArguments: [],
  });

  // Verify the Fake Marketplace Contract
  await hre.run("verify:verify", {
    address: fakeNftMarketplaceContract.target,
    constructorArguments: [],
  });

  // Verify the DAO Contract
  await hre.run("verify:verify", {
    address: daoContract.target,
    constructorArguments: [
      fakeNftMarketplaceContract.target,
      nftContract.target,
    ],
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});