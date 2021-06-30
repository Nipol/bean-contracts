async function main() {
  const ManagerFactoryTemplate = await ethers.getContractFactory('ManagerFactory');

  const ManagerFactory = await ManagerFactoryTemplate.deploy(
    '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', // UniV2Router
    '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f', // UniV2Factory
    '0x1B2eEb436757586E38cc80CC411C5324F2C6Ea92', // TokenFactory
    '0x00000000000000000000000004a772C486DEDCfF520eb1b21C9B8063f4220492', // Token template
    '0x26a26Aa3F5F0Bbb21D21520076a4cf71745B1C07', // manager
  );
  await ManagerFactory.deployed();
  console.log('ManagerFactory deployed to:', ManagerFactory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
