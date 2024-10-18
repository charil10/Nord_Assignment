const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BetSlipInsurance", function () {
    let insuranceContract;
    let owner, user1, user2;

    beforeEach(async () => {
        const BetSlipInsurance = await ethers.getContractFactory("BetSlipInsurance");
        insuranceContract = await BetSlipInsurance.deploy();
        await insuranceContract.deployed();
        [owner, user1, user2] = await ethers.getSigners();
    });

    describe("Purchase Insurance", function () {
        it("Should allow user to purchase insurance", async function () {
            const betSlipId = 1;
            const betAmount = ethers.utils.parseEther("1");
            const premium = await insuranceContract.calculatePremium(user1.address, betAmount);
            
            await expect(insuranceContract.connect(user1).purchaseInsurance(betSlipId, betAmount, { value: premium }))
                .to.emit(insuranceContract, "InsurancePurchased")
                .withArgs(betSlipId, user1.address, betAmount, premium);
            
            const insurance = await insuranceContract.insurances(betSlipId);
            expect(insurance.owner).to.equal(user1.address);
            expect(insurance.insuredAmount).to.equal(betAmount);
        });
    });

    describe("File Claim", function () {
        it("Should allow owner to file a claim", async function () {
            const betSlipId = 1;
            const betAmount = ethers.utils.parseEther("1");
            const premium = await insuranceContract.calculatePremium(user1.address, betAmount);
            await insuranceContract.connect(user1).purchaseInsurance(betSlipId, betAmount, { value: premium });

            await expect(insuranceContract.connect(user1).fileClaim(betSlipId))
                .to.emit(insuranceContract, "ClaimFiled")
                .withArgs(betSlipId, user1.address);
        });
    });

    describe("Settle Claim", function () {
        it("Should allow admin to settle a claim", async function () {
            const betSlipId = 1;
            const betAmount = ethers.utils.parseEther("1");
            const premium = await insuranceContract.calculatePremium(user1.address, betAmount);
            await insuranceContract.connect(user1).purchaseInsurance(betSlipId, betAmount, { value: premium });
            await insuranceContract.connect(user1).fileClaim(betSlipId);

            await expect(insuranceContract.connect(owner).settleClaim(betSlipId, true))
                .to.emit(insuranceContract, "ClaimSettled")
                .withArgs(betSlipId, true);
        });
    });
});
