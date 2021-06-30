// "m/44'/1'/0'/0"
// "test test test test test test test test test test test junk"
const accounts = [
  {
    //0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0
    privateKey: '0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114',
    balance: '10000000000000000000000',
  },
  {
    //0x5AEC774E6ae749DBB17A2EBA03648207A5bd7dDd
    privateKey: '0x50064dccbc8b9d9153e340ee2759b0fc4936ffe70cb451dad5563754d33c34a8',
    balance: '10000000000000000000000',
  },
  {
    //0xb6857B2E965cFc4B7394c52df05F5E93a9e4e0Dd
    privateKey: '0x95c674cabc4b9885d930d2c0f592fdde8dc24b4e6a43ae05c6ada58edb9f54ae',
    balance: '10000000000000000000000',
  },
  {
    //0x2E1eD4eEd20c338378800d8383a54E3329957c3d
    privateKey: '0x24af27ccb29738cdaba736d8e35cb4d43ace56e1c83389f48feb746b38cf2a05',
    balance: '10000000000000000000000',
  },
  {
    //0x7DC241C040A66542139890Ff7872824f5440aFD3
    privateKey: '0xb21deff810a52cded6c3f9a0f57184f1c70ff08cc3097bec420aa39c7693ed8c',
    balance: '10000000000000000000000',
  },
];

module.exports = {
  providerOptions: {
    accounts
  },
  skipFiles: ['Migrations.sol', 'Token.sol', 'oz', 'gnosis-safe'],
};
