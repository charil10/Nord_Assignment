# Nord_Assignment
## Overview

The Azuro Betting Protocol is a decentralized betting platform built on Ethereum that facilitates peer-to-peer betting on various events. It comprises three main components:

1. **BetSlipNFT** - An ERC721 token representing individual bet slips.
2. **PredictionMarket** - A contract for managing betting events, placing bets, and resolving outcomes.
3. **BetSlipInsurance** - A system that provides insurance for bet slips.

## Features

- Create betting events with multiple outcomes.
- Place bets on outcomes using Ether.
- Claim payouts based on event results.
- Purchase insurance for bets.
- File claims for insurance payouts.
- Cancel events and refund bettors.

## Requirements

- Node.js >= 14.x
- npm >= 5.x
- Hardhat >= 2.22.2

## Setup

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd Nord_Assignment
   
 Install dependencies:
npm install

 Set up Hardhat:
npx hardhat

## Deploy the contracts:

Edit the deployment script in the scripts folder as necessary and run:
npx hardhat run scripts/deploy.js --network <network>



-Interacting with the Contracts
Once deployed, you can interact with the contracts via the Hardhat console or by writing scripts in the scripts directory.

Creating an Event
const predictionMarket = await PredictionMarket.deployed();
await predictionMarket.createEvent("Event Name", ["Outcome 1", "Outcome 2"], duration);


Placing a Bet
await predictionMarket.placeBet(eventId, outcome, { value: betAmount });


Resolving an Event
await predictionMarket.resolveEvent(eventId, winningOutcome);

Claiming Payout
await predictionMarket.claimPayout(eventId, betSlipId);
Purchasing Insurance


await betSlipInsurance.purchaseInsurance(betSlipId, betAmount, { value: premium });
Filing a Claim


await betSlipInsurance.fileClaim(betSlipId);
Settling a Claim


await betSlipInsurance.settleClaim(betSlipId, approve);
Running Tests

To run tests, execute:
npx hardhat test


---

### Design Choices and Assumptions Document

```markdown
# Design Choices and Assumptions

## Overview

The Azuro Betting Protocol is designed to facilitate decentralized betting, allowing users to place bets on various events with insurance options to protect their wagers. The system includes robust event management and payout mechanisms.

## Smart Contracts

### BetSlipNFT
- **ERC721 Compliance**: Utilizes the ERC721 standard to represent unique bet slips, ensuring each bet is individually tracked and owned.
- **Ownership Transfer**: Allows the prediction market contract to manage ownership efficiently, ensuring smooth interactions.

### PredictionMarket
- **Event Management**: Each event can have multiple outcomes, enabling diverse betting options. Events can be created with a name, multiple outcomes, and a specified deadline.
- **Betting Logic**: Users can place bets by sending Ether, with the system tracking total pools and individual bet details.
- **Event Cancellation**: Provides flexibility for event management. If an event is canceled, bettors are refunded automatically.

### BetSlipInsurance
- **Insurance Logic**: Allows users to purchase insurance for their bets, which provides a safety net for their wagers.
- **Claim System**: Users can file claims for payouts based on specific conditions outlined in the contract.

## Assumptions
- The contracts assume all interactions are performed by users with a sufficient Ether balance.
- Users are responsible for managing their private keys to ensure the security of their funds.
- Events must be resolved by the owner, which centralizes some control over the outcome declaration process.

## Future Improvements
- Implement a decentralized oracle system for resolving events, reducing reliance on the contract owner for event outcomes.
- Enhance security measures to protect against reentrancy attacks and other vulnerabilities.
- Optimize gas usage for complex operations, particularly in functions involving loops and state updates.


