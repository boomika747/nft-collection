const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('NftCollection', () => {
  let nftContract;
  let owner, addr1, addr2, addr3;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const NftCollection = await ethers.getContractFactory('NftCollection');
    nftContract = await NftCollection.deploy('TestNFT', 'TNFT', 1000, 'https://api.example.com/');
    await nftContract.waitForDeployment();
  });

  describe('Initial', () => {
    it('Should have correct name', async () => {
      expect(await nftContract.name()).to.equal('TestNFT');
      expect(await nftContract.symbol()).to.equal('TNFT');
    });
  });

  describe('Minting', () => {
    it('Should mint token', async () => {
      await nftContract.safeMint(addr1.address, 1);
      expect(await nftContract.balanceOf(addr1.address)).to.equal(1);
    });
  });

  describe('Transfers', () => {
    beforeEach(async () => {
      await nftContract.safeMint(addr1.address, 1);
    });

    it('Should transfer token', async () => {
      await nftContract.connect(addr1).transferFrom(addr1.address, addr2.address, 1);
      expect(await nftContract.ownerOf(1)).to.equal(addr2.address);
    });
  });

  describe('Burning', () => {
    beforeEach(async () => {
      await nftContract.safeMint(addr1.address, 1);
    });

    it('Should burn token', async () => {
      await nftContract.connect(addr1).burn(1);
      expect(await nftContract.totalSupply()).to.equal(0);
    });
  });
});
