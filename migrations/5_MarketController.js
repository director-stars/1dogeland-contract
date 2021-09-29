const MarketController = artifacts.require("MarketController")
module.exports = async function (deployer) {
  await deployer.deploy(MarketController);
};