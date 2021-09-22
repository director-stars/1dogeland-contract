const CryptoDogeNFT = artifacts.require("CryptoDogeNFT")
module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(CryptoDogeNFT, "CryptoDogeNFT", "CryptoDogeNFT", accounts[0], '0x40619dc9F00ea34e51D96b6EC5d8a6aD75457434');
};