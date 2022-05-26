const { expect } = require("chai");
const { ethers } = require("hardhat");
const { SignHelper } = require("../utils/signHelper");

async function sign() {
  const [signer, minter] = await ethers.getSigners();
  const NFT = await ethers.getContractFactory("NFT", signer);
  const nft = await NFT.deploy();
  console.log("nft: " + nft.address);
  //* the redeemerContract is an instance of the contract that's wired up to the redeemer's signing key
  const minterFactory = nft.connect(minter);
  const minterContract = minterFactory.attach(nft.address);

  return { signer, nft, minter, minterFactory, minterContract };
}

describe("NFT Minting", function () {
  it("should deploy", async function () {
    const [signer] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("NFT", signer);
    const nft = await NFT.deploy();
    await nft.deployed();
  });

  it("Should return minter role", async function () {
    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy();
    console.log("nft: " + nft.address);
    await nft.deployed();

    const minterRole = await nft.MINTER_ROLE();

    console.log(minterRole);
    expect(minterRole).to.equal(
      "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
    );
  });
  it("Should mint token", async function () {
    const { signer, nft, minter, minterFactory, minterContract } = await sign();
    const signature = new SignHelper({ nft, signer });
    const minPrice = ethers.utils.parseUnits("0.000000008", "ether");

    console.log("minPrice: " + minPrice);
    console.log("minter: " + minter.address);
    console.log("redeemer: " + signer.address);
    const voucher = await signature.createSignature(
      1,
      minPrice,
      "http://ipfs.pics/QmR7D9ZCBbQrzND6WPJovMWJrJaFyT7tmUFoSqdesxVc2i"
    );
    await expect(
      minterContract.mintToken(minter.address, voucher, {
        value: voucher.minPrice,
      })
    )
      .to.emit(nft, "Transfer")
      .withArgs(
        "0x0000000000000000000000000000000000000000",
        signer.address,
        voucher.tokenId
      )
      .and.to.emit(nft, "Transfer")
      .withArgs(signer.address, minter.address, 1);
  });
});
