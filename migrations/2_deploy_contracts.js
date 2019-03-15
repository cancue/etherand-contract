const Etherand = artifacts.require("./Etherand.sol");

module.exports = function(deployer) {
  deployer.deploy(Etherand);
};
