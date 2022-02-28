import { ethers } from 'hardhat';

export const computeCreateAddress = async (sender: string): Promise<string> => {
  const txCount = await ethers.provider.getTransactionCount(sender);
  return ethers.utils.getContractAddress({ from: sender, nonce: txCount });
};
