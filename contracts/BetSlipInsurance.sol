// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BetSlipInsurance {
    struct Insurance {
        uint256 betSlipId;
        uint256 insuredAmount;
        uint256 premiumPaid;
        address owner;
        bool isClaimed;
    }

    struct Claim {
        uint256 betSlipId;
        address claimant;
        bool isSettled;
        bool isApproved;
        uint256 timestamp; // Timestamp when the claim was filed
    }

    mapping(uint256 => Insurance) public insurances; // Maps bet slip ID to Insurance details 
    mapping(uint256 => Claim) public claims; // Maps bet slip ID to Claim details
    mapping(address => uint256) public successfulClaims; // Tracks the number of successful claims per user

    address public admin;
    uint256 public basePremiumRate = 30; // Base premium rate as a percentage
    uint256 public timeLockPeriod = 1 days; // Time lock period for claim settlements

    event InsurancePurchased(uint256 indexed betSlipId, address indexed owner, uint256 insuredAmount, uint256 premium);
    event ClaimFiled(uint256 indexed betSlipId, address indexed claimant);
    event ClaimSettled(uint256 indexed betSlipId, bool approved);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyOwner(uint256 betSlipId) {
        require(insurances[betSlipId].owner == msg.sender, "Not the owner of this insurance");
        _;
    }

    modifier onlyValidBetSlip(uint256 betSlipId) {
        require(insurances[betSlipId].betSlipId != 0, "Insurance does not exist for this bet slip");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Tiered premium calculation based on the user's claim history
    function calculatePremium(address user, uint256 betAmount) public view returns (uint256) {
        uint256 successfulClaimsCount = successfulClaims[user];

        // Premium increases by 5% for every successful claim, capped at 50%
        uint256 adjustedPremiumRate = basePremiumRate + (successfulClaimsCount * 5);
        if (adjustedPremiumRate > 50) {
            adjustedPremiumRate = 50;
        }

        return (betAmount * adjustedPremiumRate) / 100;
    }

    function purchaseInsurance(uint256 betSlipId, uint256 betAmount) external payable {
        require(insurances[betSlipId].betSlipId == 0, "Insurance already exists for this bet slip");

        uint256 premium = calculatePremium(msg.sender, betAmount);
        require(msg.value == premium, "Incorrect premium amount sent");

        // Create insurance record
        Insurance memory newInsurance = Insurance({
            betSlipId: betSlipId,
            insuredAmount: betAmount,
            premiumPaid: premium,
            owner: msg.sender,
            isClaimed: false
        });

        insurances[betSlipId] = newInsurance;

        emit InsurancePurchased(betSlipId, msg.sender, betAmount, premium);
    }

    function fileClaim(uint256 betSlipId) external onlyOwner(betSlipId) onlyValidBetSlip(betSlipId) {
        Insurance storage insurance = insurances[betSlipId];
        require(!insurance.isClaimed, "Claim already filed");

        // Create claim record
        Claim memory newClaim = Claim({
            betSlipId: betSlipId,
            claimant: msg.sender,
            isSettled: false,
            isApproved: false,
            timestamp: block.timestamp
        });

        claims[betSlipId] = newClaim;
        insurance.isClaimed = true;

        emit ClaimFiled(betSlipId, msg.sender);
    }

    function settleClaim(uint256 betSlipId, bool approve) external onlyAdmin onlyValidBetSlip(betSlipId) {
        Claim storage claim = claims[betSlipId];
        Insurance storage insurance = insurances[betSlipId];

        require(!claim.isSettled, "Claim already settled");
        require(block.timestamp >= claim.timestamp + timeLockPeriod, "Claim settlement is locked");

        claim.isSettled = true;
        claim.isApproved = approve;

        if (approve) {
            // Transfer insured amount to claimant
            payable(claim.claimant).transfer(insurance.insuredAmount);
            // Track successful claims
            successfulClaims[claim.claimant]++;
        }

        emit ClaimSettled(betSlipId, approve);
    }

    // Admin can update the time lock period (in seconds)
    function updateTimeLockPeriod(uint256 newTimeLockPeriod) external onlyAdmin {
        timeLockPeriod = newTimeLockPeriod;
    }

    // Function to retrieve insurance details
    function getInsuranceDetails(uint256 betSlipId) external view returns (Insurance memory) {
        return insurances[betSlipId];
    }

    // Function to retrieve claim details
    function getClaimDetails(uint256 betSlipId) external view returns (Claim memory) {
        return claims[betSlipId];
    }
}
