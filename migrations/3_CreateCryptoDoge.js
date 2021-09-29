const CreateCryptoDoge = artifacts.require("CreateCryptoDoge")
module.exports = async function (deployer) {
  await deployer.deploy(CreateCryptoDoge);
};