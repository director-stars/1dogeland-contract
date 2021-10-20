const MagicStoneController = artifacts.require("MagicStoneController")
module.exports = async function (deployer) {
  await deployer.deploy(MagicStoneController);
};