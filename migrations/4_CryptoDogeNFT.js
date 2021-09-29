const CryptoDogeNFT = artifacts.require("CryptoDogeNFT")
module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(CryptoDogeNFT, "CryptoDogeNFT", "CryptoDogeNFT", accounts[0], '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56');
};