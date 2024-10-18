const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PredictionMarket", function () {
    let predictionMarket;
    let betSlipNFT;
    let owner, user1;

    beforeEach(async () => {
        const BetSlipNFT = await ethers.getContractFactory("BetSlipNFT");
        betSlipNFT = await BetSlipNFT.deploy();
        await betSlipNFT.deployed();
        const PredictionMarket = await ethers.getContractFactory("PredictionMarket");
        predictionMarket = await PredictionMarket.deploy(betSlipNFT.address);
        await predictionMarket.deployed();

        [owner, user1] = await ethers.getSigners();
    });

    describe("Create Event", function () {
        it("Should allow owner to create an event", async function () {
            const outcomes = ["Team A", "Team B"];
            await expect(predictionMarket.createEvent("Match 1", outcomes, 86400))
                .to.emit(predictionMarket, "EventCreated");
        });
    });

    describe("Place Bet", function () {
        it("Should allow users to place bets", async function () {
            const outcomes = ["Team A", "Team B"];
            await predictionMarket.createEvent("Match 1", outcomes, 86400);
            await expect(predictionMarket.connect(user1).placeBet(0, 0, { value: ethers.utils.parseEther("1") }))
                .to.emit(predictionMarket, "BetPlaced");
        });
    });

    describe("Resolve Event", function () {
        it("Should allow owner to resolve an event", async function () {
            const outcomes = ["Team A", "Team B"];
            await predictionMarket.createEvent("Match 1", outcomes, 86400);
            await predictionMarket.placeBet(0, 0, { value: ethers.utils.parseEther("1") });

            await expect(predictionMarket.resolveEvent(0, 0))
                .to.emit(predictionMarket, "EventResolved");
        });
    });

    describe("Claim Payout", function () {
        it("Should allow user to claim payout if they win", async function () {
            const outcomes = ["Team A", "Team B"];
            await predictionMarket.createEvent("Match 1", outcomes, 86400);
            await predictionMarket.placeBet(0, 0, { value: ethers.utils.parseEther("1") });
            await predictionMarket.resolveEvent(0, 0); // Assuming Team A wins

            await expect(predictionMarket.connect(user1).claimPayout(0, 1))
                .to.emit(predictionMarket, "Payout");
        });
    });

    describe("Cancel Event", function () {
        it("Should allow owner to cancel an event", async function () {
            const outcomes = ["Team A", "Team B"];
            await predictionMarket.createEvent("Match 1", outcomes, 86400);
            await predictionMarket.cancelEvent(0);
            const eventDetails = await predictionMarket.getEventDetails(0);
            expect(eventDetails.isCanceled).to.be.true;
        });
    });
});
