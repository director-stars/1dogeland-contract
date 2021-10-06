const MagicStoneNFT = artifacts.require("MagicStoneNFT")
module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(MagicStoneNFT, "MagicStoneNFT", "MagicStoneNFT", accounts[0]);
};