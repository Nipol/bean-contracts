async function main() {
  const ManagerTemplate = await ethers.getContractFactory('Manager');

  const Manager = await ManagerTemplate.deploy();
  await Manager.deployed();
  await Manager.initialize(
    '0x0000000000000000000000000000000000000000',
    '0x0000000000000000000000000000000000000000',
    '0',
    0,
  );
  // const TokenFactory = await TokenFactoryTemplate.deploy();
  // await TokenFactory.deployed();
  // await TokenFactory.newTemplate('0x644fE2731D8235216aA1DBfF4b4e844A9937173C', 0);

  // console.log('StandardToken deployed to:', '0x644fE2731D8235216aA1DBfF4b4e844A9937173C');
  console.log('Manager deployed to:', Manager.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
