const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("XSeedToken", function () {
  it("Owner's balance should be same as the total supply.", async function () {
    const [owner] = await ethers.getSigners();

    const XSeedToken = await ethers.getContractFactory("XSeedToken");
    const xSeed = await XSeedToken.deploy();
    await xSeed.deployed();

    const ownerBalance = await xSeed.balanceOf(owner.address);
    expect(await xSeed.totalSupply()).to.equal(ownerBalance);
  });
});
