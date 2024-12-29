// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Lottery contract: Pay 1 ETH for the chance of winning 20 ETH
contract Lottery {
    address public owner;
    uint256 public constant ENTRY_FEE = 1 ether;
    uint256 public constant PRIZE = 20 ether;
    bool public isActive;
    uint8 randomNumber; // Make public for testing
    
    event GameStarted(uint256 initialBalance);
    event GuessMade(address indexed player, uint8 guess);
    event Winner(address indexed winner, uint256 prizeAmount);
    event FundingReceived(uint256 amount);

    // Constructor
    constructor() payable {
        require(msg.value >= PRIZE, "Must fund contract with at least 20 ETH");
        owner = msg.sender;
        isActive = true;
        generateRandomNumber();
        emit GameStarted(msg.value);
        emit FundingReceived(msg.value);
    }

    // Specify modifier for owner-only actions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Generate a pseudo-random number between 1 and 20
    function generateRandomNumber() private {
        // Using multiple block properties and addresses for better randomness
        bytes32 hash = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                msg.sender,
                address(this),
                block.number
            )
        );
        // Generate pseudo-random number between 1 and 20
        randomNumber = uint8((uint256(hash) % 20) + 1);
    }

    // Attempt to guess the random value
    function guess(uint8 value) public payable {
        require(isActive, "Game is not active");
        require(msg.value == ENTRY_FEE, "Incorrect entry fee");
        require(value >= 1 && value <= 20, "Guess must be between 1 and 20");
        
        uint256 currentBalance = address(this).balance;
        require(currentBalance >= PRIZE, "Contract has insufficient balance");

        emit GuessMade(msg.sender, value);
        
        if (value == randomNumber) {
            // Guessed value => pay the pize
            isActive = false;
            (bool success, ) = payable(msg.sender).call{value: PRIZE}("");
            require(success, "Transfer failed");
            emit Winner(msg.sender, PRIZE);
        }
    }

    // Obtain the contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Check if the contract has sufficient funds for paying the prize
    function hasSufficientFunds() public view returns (bool) {
        return address(this).balance >= PRIZE;
    }

    // Restart the game with optional additional funding (owner only)
    function restartGame() public payable onlyOwner {
        require(!isActive, "Game is already active");
        
        uint256 newBalance = address(this).balance + msg.value;
        require(newBalance >= PRIZE, "Total balance must be at least 20 ETH to restart");
        
        isActive = true;
        generateRandomNumber();
        emit GameStarted(newBalance);
        
        if (msg.value > 0) {
            emit FundingReceived(msg.value);
        }
    }

    // Withdraw funds (owner only)
    function withdrawFunds() public onlyOwner {
        require(!isActive, "Game is still active");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
    }

    receive() external payable {
        emit FundingReceived(msg.value);
    }
}