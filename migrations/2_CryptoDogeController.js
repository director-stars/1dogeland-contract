const CryptoDogeController = artifacts.require("CryptoDogeController")
module.exports = async function (deployer) {
  await deployer.deploy(CryptoDogeController);
};