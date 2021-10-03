const OneDoge = artifacts.require("OneDoge")
module.exports = async function(deployer) {
  await deployer.deploy(OneDoge);
};