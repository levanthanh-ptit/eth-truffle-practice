const TableLib = artifacts.require('TableLib');
const ThreeCards = artifacts.require('ThreeCards');

module.exports = async function (deployer) {
  deployer.deploy(TableLib);
  deployer.link(TableLib, ThreeCards);
  deployer.deploy(ThreeCards);
};
