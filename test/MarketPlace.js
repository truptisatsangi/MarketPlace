const { expect } = require("chai");
const { ethers } = require("hardhat");
const chai = require("chai");
const { describe } = require("mocha");
chai.use(require("chai-bignumber")(ethers.BigNumber));

describe("MarketPlace", async function () {
  before(async function () {
    const MarketPlace = await hre.ethers.getContractFactory("MarketPlace");
    marketplace = await MarketPlace.deploy();
    await marketplace.deployed();

    token20 = await hre.ethers.getContractFactory("token20");
    token20 = await token20.deploy();
    await token20.deployed();

    nft1155 = await hre.ethers.getContractFactory("nft1155");
    nft1155 = await nft1155.deploy();
    await nft1155.deployed();

    nft721 = await hre.ethers.getContractFactory("nft721");
    nft721 = await nft721.deploy();
    await nft721.deployed();

    console.log(`MarketPlace deployed to ${marketplace.address}`);
    console.log(`token20 deployed to ${token20.address}`);
    console.log(`nft1155 deployed to ${nft1155.address}`);
    console.log(`nft721 deployed to ${nft721.address}`);

    [owner, buyer] = await ethers.getSigners();

    await token20.mint(buyer.address, 20);
    await nft1155.mint(owner.address, 1, 5);
    await nft721.mint(owner.address, 7);

    console.log("token20 balance", await token20.balanceOf(buyer.address));
    console.log("nft721 balance", await nft721.balanceOf(owner.address));
    console.log("nft1155 balance", await nft1155.balanceOf(owner.address, 1));
  });

  describe("register1155NFT", async function () {
    it("should revert ", async function () {
      const [owner, buyer] = await ethers.getSigners();

      await expect(
        marketplace.registerERC1155Token(
          nft1155.address,
          1,
          6,
          3,
          token20.address,
          ""
        )
      ).to.be.revertedWith("Not having required number of assets");
    });
    it("should emit 'TokenRegistered' event ", async function () {
      expect(
        await marketplace.registerERC1155Token(
          nft1155.address,
          1,
          3,
          3,
          token20.address,
          ""
        )
      ).to.emit(marketplace, "TokenRegistered");
      nft1155.setApprovalForAll(marketplace.address, true);
    });

    it("should revert", async function () {
      expect(
        await marketplace
          .connect(owner)
          .registerERC1155Token(nft1155.address, 1, 3, 3, nft1155.address, "")
      ).to.revertedWith("Different address");
      nft1155.setApprovalForAll(marketplace.address, true);
    });

    it("should emit buyToken", async function () {
      await marketplace.registerERC1155Token(
        nft1155.address,
        1,
        3,
        3,
        token20.address,
        ""
      );

      await token20.connect(buyer).Approve(marketplace.address, 4);
      await nft1155.connect(owner).setApprovalForAll(marketplace.address, true);
      expect(
        await marketplace.connect(buyer).buy(token20.address, 1, 1, 4)
      ).to.emit(marketplace, "buyToken");
      console.log("balance1", await token20.balanceOf(owner.address));
    });
  });

  describe("registerNFT721", async function () {
    it("should revert ", async function () {
      await expect(
        marketplace.registerERC721Token(
          nft721.address,
          8,
          3,
          token20.address,
          ""
        )
      ).to.be.revertedWith("ERC721: invalid token ID");
    });
    it("should emit 'TokenRegistered' event ", async function () {
      expect(
        await marketplace.registerERC721Token(
          nft721.address,
          7,
          3,
          token20.address,
          ""
        )
      ).to.emit(marketplace, "TokenRegistered");
      nft721.approve(marketplace.address, 7);
    });

    it("should revert", async function () {
      expect(
        await marketplace
          .connect(owner)
          .registerERC721Token(nft721.address, 7, 3, nft721.address, "")
      ).to.revertedWith("Different address");
    });

    it("should emit buyToken", async function () {
      await marketplace.registerERC721Token(
        nft721.address,
        7,
        3,
        token20.address,
        ""
      );

      await token20.connect(buyer).Approve(marketplace.address, 3);
      await nft721.connect(owner).approve(marketplace.address, 7);
      expect(
        await marketplace.connect(buyer).buy(token20.address, 7, 1, 3)
      ).to.emit(marketplace, "buyToken");
      console.log("balance2", await token20.balanceOf(owner.address));
    });
  });
});
