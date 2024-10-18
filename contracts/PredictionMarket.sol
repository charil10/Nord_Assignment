// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BetSlipNFT.sol";

contract PredictionMarket is Ownable, ReentrancyGuard {
    struct Event {
        string name;
        string[] outcomes;
        bool isResolved;
        uint8 winningOutcome;
        uint256 deadline;
        uint256 totalPool;
        mapping(uint8 => uint256) outcomePools;
        mapping(uint256 => BetDetail) betDetails; 
        address[] bettors;
        bool isCanceled;
    }

    struct BetDetail {
        address owner;
        uint8 outcome;
        uint256 amount;
        bool claimed;
    }

    BetSlipNFT public betSlipNFT;
    mapping(uint256 => Event) public events;
    uint256 public eventCount;

    // Mapping from user address to their bet IDs for all events
    mapping(address => uint256[]) public userBets;

    event EventCreated(
        uint256 indexed eventId,
        string name,
        string[] outcomes,
        uint256 deadline
    );
    event BetPlaced(
        address indexed user,
        uint256 indexed eventId,
        uint8 outcome,
        uint256 betAmount,
        uint256 betSlipId
    );
    event EventResolved(uint256 indexed eventId, uint8 winningOutcome);
    event Payout(address indexed user, uint256 indexed eventId, uint256 amount);
    event EventCanceled(uint256 indexed eventId);

    constructor(address betSlipNFTAddress) Ownable(msg.sender) {
                betSlipNFT = BetSlipNFT(betSlipNFTAddress);
                betSlipNFT.transferOwnership(address(this));
    }

    modifier onlyBeforeDeadline(uint256 eventId) {
        require(
            block.timestamp < events[eventId].deadline,
            "Betting period is over"
        );
        require(!events[eventId].isCanceled, "Event is canceled");
        _; 
    }

    modifier onlyAfterDeadline(uint256 eventId) {
        require(
            block.timestamp >= events[eventId].deadline,
            "Betting period is not over"
        );
        require(!events[eventId].isCanceled, "Event is canceled");
        _; 
    }

    modifier onlyBettor(uint256 eventId) {
        require(events[eventId].bettors.length > 0, "No bettors for this event");
        _; 
    }

    modifier validOutcome(uint256 eventId, uint8 outcome) {
        require(outcome < events[eventId].outcomes.length, "Invalid outcome");
        _; 
    }

    function createEvent(
        string memory name,
        string[] memory outcomes,
        uint256 duration
    ) external onlyOwner {
        require(outcomes.length >= 2, "Need at least two possible outcomes");

        Event storage newEvent = events[eventCount];
        newEvent.name = name;
        newEvent.outcomes = outcomes;
        newEvent.deadline = block.timestamp + duration;

        emit EventCreated(eventCount, name, outcomes, newEvent.deadline);
        eventCount++;
    }

    function placeBet(uint256 eventId, uint8 outcome)
        external
        payable
        nonReentrant
        onlyBeforeDeadline(eventId)
        validOutcome(eventId, outcome)
    {
        require(msg.value > 0, "Must place a bet greater than zero");

        Event storage bettingEvent = events[eventId];
        bettingEvent.totalPool += msg.value;
        bettingEvent.outcomePools[outcome] += msg.value;

        string memory tokenURI = generateBetSlipMetadata(
            eventId,
            outcome,
            msg.value
        );
        uint256 betSlipId = betSlipNFT.mintBetSlip(msg.sender, tokenURI);

        bettingEvent.betDetails[betSlipId] = BetDetail(
            msg.sender,
            outcome,
            msg.value,
            false
        );
        bettingEvent.bettors.push(msg.sender);
        userBets[msg.sender].push(betSlipId); // Store bet ID for user

        emit BetPlaced(msg.sender, eventId, outcome, msg.value, betSlipId);
    }

    function resolveEvent(uint256 eventId, uint8 winningOutcome)
        external
        onlyOwner
        onlyAfterDeadline(eventId)
    {
        Event storage bettingEvent = events[eventId];
        require(!bettingEvent.isResolved, "Event already resolved");
        require(
            winningOutcome < bettingEvent.outcomes.length,
            "Invalid outcome"
        );

        bettingEvent.isResolved = true;
        bettingEvent.winningOutcome = winningOutcome;

        emit EventResolved(eventId, winningOutcome);
    }

    function claimPayout(uint256 eventId, uint256 betSlipId)
        external
        nonReentrant
        onlyBettor(eventId)
    {
        Event storage bettingEvent = events[eventId];
        BetDetail storage bet = bettingEvent.betDetails[betSlipId];

        require(bettingEvent.isResolved, "Event not resolved");
        require(bet.owner == msg.sender, "Not the bet owner");
        require(!bet.claimed, "Payout already claimed");
        require(bet.outcome == bettingEvent.winningOutcome, "Bet did not win");

        uint256 totalWinningPool = bettingEvent.outcomePools[bettingEvent.winningOutcome];
        uint256 payout = (bet.amount * bettingEvent.totalPool) / totalWinningPool;

        bet.claimed = true;
        payable(msg.sender).transfer(payout);

        emit Payout(msg.sender, eventId, payout);
    }

    function cancelEvent(uint256 eventId)
        external
        onlyOwner
        onlyBeforeDeadline(eventId)
    {
        Event storage bettingEvent = events[eventId];
        require(!bettingEvent.isResolved, "Event already resolved");
        bettingEvent.isCanceled = true;

        // Refund bettors
        for (uint256 i = 0; i < bettingEvent.bettors.length; i++) {
            BetDetail storage bet = bettingEvent.betDetails[i];
            if (!bet.claimed) {
                payable(bet.owner).transfer(bet.amount);
                bet.claimed = true; // Mark refunded to avoid double payouts
            }
        }

        emit EventCanceled(eventId);
    }

    function getEventDetails(uint256 eventId)
        external
        view
        returns (
            string memory name,
            string[] memory outcomes,
            bool isResolved,
            uint8 winningOutcome,
            uint256 deadline,
            uint256 totalPool,
            address[] memory bettors,
            bool isCanceled
        )
    {
        Event storage bettingEvent = events[eventId];
        return (
            bettingEvent.name,
            bettingEvent.outcomes,
            bettingEvent.isResolved,
            bettingEvent.winningOutcome,
            bettingEvent.deadline,
            bettingEvent.totalPool,
            bettingEvent.bettors,
            bettingEvent.isCanceled
        );
    }

    function getUserBetDetails(uint256 eventId, address userAddress)
        external
        view
        returns (
            uint8 outcome,
            uint256 amount,
            bool claimed
        )
    {
        Event storage bettingEvent = events[eventId];
        for (uint256 i = 0; i < bettingEvent.bettors.length; i++) {
            BetDetail storage bet = bettingEvent.betDetails[i];
            if (bet.owner == userAddress) {
                return (bet.outcome, bet.amount, bet.claimed);
            }
        }
        revert("No bets found for this user on the event");
    }

    function getAllUserBets(address userAddress)
        external
        view
        returns (BetDetail[] memory)
    {
        uint256[] memory betIds = userBets[userAddress];
        BetDetail[] memory userBetDetails = new BetDetail[](betIds.length);

        for (uint256 i = 0; i < betIds.length; i++) {
            userBetDetails[i] = events[betIds[i]].betDetails[betIds[i]];
        }

        return userBetDetails;
    }

    // Function to convert uint256 to string for metadata
    function uint2str(uint256 _i) private pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length = 0;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        while (_i != 0) {
            length -= 1;
            bstr[length] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    // Function to generate metadata of betting using eventId, outcome, and amount
    function generateBetSlipMetadata(
        uint256 eventId,
        uint8 outcome,
        uint256 amount
    ) public pure returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                "{",
                '"name": "Bet Slip #',
                uint2str(eventId),
                '",',
                '"description": "Bet slip for event #',
                uint2str(eventId),
                ' with outcome ',
                uint2str(outcome),
                '",',
                '"attributes": [',
                "{",
                '"trait_type": "Event ID",',
                '"value": "',
                uint2str(eventId),
                '"',
                "},",
                "{",
                '"trait_type": "Outcome",',
                '"value": "',
                uint2str(outcome),
                '"',
                "},",
                "{",
                '"trait_type": "Amount",',
                '"value": "',
                uint2str(amount),
                '"',
                "}",
                "]",
                "}"
            )
        );
        return metadata;
    }
}
