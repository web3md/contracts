usePlugin("@nomiclabs/buidler-ethers");
usePlugin("@nomiclabs/buidler-waffle");
usePlugin("buidler-spdx-license-identifier");
usePlugin("buidler-deploy");
// usePlugin("buidler-gas-reporter");

require("dotenv/config");

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();
  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

module.exports = {
  defaultNetwork: "buidlerevm",
  networks: {
    buidlerevm: {
      gas: 12000000,
      blockGasLimit: 12000000,
      allowUnlimitedContractSize: true,
    },
    kovan: {
      url:
        "https://eth-kovan.alchemyapi.io/v2/eRvHBkwNnm65K0KiQbNihiTyjktIGtbo",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  namedAccounts: {
    deployer: 0,
  },
  solc: {
    version: "0.6.12",
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
