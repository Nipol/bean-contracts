async function main() {
  const StandardTokenTemplate = await ethers.getContractFactory('StandardToken');
  const TokenFactoryTemplate = await ethers.getContractFactory('TokenFactory');

  // const StandardToken = await StandardTokenTemplate.deploy();
  // await StandardToken.deployed();
  // await StandardToken.initialize('1', 'Template', 'TEMP', 18);
  const TokenFactory = await TokenFactoryTemplate.deploy();
  await TokenFactory.deployed();
  await TokenFactory.newTemplate('0x644fE2731D8235216aA1DBfF4b4e844A9937173C', 0);

  console.log('StandardToken deployed to:', '0x644fE2731D8235216aA1DBfF4b4e844A9937173C');
  console.log('TokenFactory deployed to:', TokenFactory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
