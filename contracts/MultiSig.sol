// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MultiSig {
    // State Variables
    address[] public owners; // Array of wallet owners
    uint256 public required; // Number of required confirmations

    // Transaction Structure
    struct Transaction {
        address destination; // Recipient address
        uint256 value;       // Amount in wei
        bytes data;          // Additional data (calldata)
        bool executed;       // Execution status
    }

    // Array of Transactions
    Transaction[] public transactions;

    // Confirmation Mapping
    mapping(uint256 => mapping(address => bool)) public confirmations;

    // Events
    event TransactionCreated(uint256 transactionId, address destination, uint256 value, bytes data);
    event TransactionConfirmed(uint256 transactionId, address owner);
    event TransactionExecuted(uint256 transactionId);

    // Constructor
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid number of required confirmations"
        );

        owners = _owners;
        required = _required;
    }

    // Add a New Transaction
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal returns (uint256) {
        transactions.push(Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        }));
        uint256 transactionId = transactions.length - 1;
        emit TransactionCreated(transactionId, destination, value, data);
        return transactionId;
    }

    // Confirm a Transaction
    function confirmTransaction(uint256 transactionId) public {
        require(isOwner(msg.sender), "Only owners can confirm");
        require(transactionId < transactions.length, "Invalid transaction ID");
        require(!confirmations[transactionId][msg.sender], "Already confirmed");

        confirmations[transactionId][msg.sender] = true;
        emit TransactionConfirmed(transactionId, msg.sender);

        if (isConfirmed(transactionId)) {
            executeTransaction(transactionId);
        }
    }

    // Execute a Transaction
    function executeTransaction(uint256 transactionId) internal {
        Transaction storage txn = transactions[transactionId];

        require(!txn.executed, "Transaction already executed");
        require(isConfirmed(transactionId), "Transaction not confirmed");

        (bool success, ) = txn.destination.call{ value: txn.value }(txn.data);
        require(success, "Transaction execution failed");

        txn.executed = true;
        emit TransactionExecuted(transactionId);
    }

    // Execute ERC20 Token Transfers
    function executeERC20Transfer(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external {
        require(isOwner(msg.sender), "Only owners can execute ERC20 transfers");

        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", recipient, amount);
        uint256 transactionId = addTransaction(tokenAddress, 0, data);

        confirmTransaction(transactionId);
    }

    // Check if a Transaction is Confirmed
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count >= required;
    }

    // Check if an Address is an Owner
    function isOwner(address addr) internal view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    // Receive Ether
    receive() external payable {}
}
