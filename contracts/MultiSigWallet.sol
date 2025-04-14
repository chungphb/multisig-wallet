// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MultiSigWallet {
    // Events.
    event ProposeTransaction(uint indexed txId, address indexed to, uint value, bytes data);
    event ApproveTransaction(address indexed owner, uint indexed txId);
    event RejectTransaction(address indexed owner, uint indexed txId);
    event ConfirmTransaction(uint indexed txId);

    // State variables.
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public requiredApprovals;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numApprovals;
    }
    Transaction[] public transactions;

    mapping(uint => mapping(address => bool)) public approvals;

    // Modifiers.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint txId) {
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier txNotExecuted(uint txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    modifier txNotApproved(uint txId) {
        require(!approvals[txId][msg.sender], "Transaction already approved");
        _;
    }

    // Constructor.
    constructor(address[] memory _owners, uint _requiredApprovals) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "Invalid number of required approvals"
        );

        for (uint i = 0; i < _owners.length; ++i) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    // Functions
    function getTransaction(uint txId)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numApprovals
        )
    {
        Transaction storage transaction = transactions[txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numApprovals
        );
    }

    function proposeTransaction(address _to, uint _value, bytes memory _data)
        public
        onlyOwner
    {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numApprovals: 0
        }));
        emit ProposeTransaction(transactions.length - 1, _to, _value, _data);
    }

    function approveTransaction(uint txId)
        public
        onlyOwner
        txExists(txId)
        txNotApproved(txId)
        txNotExecuted(txId)
    {
        approvals[txId][msg.sender] = true;
        transactions[txId].numApprovals++;
        emit ApproveTransaction(msg.sender, txId);
    }

    function rejectTransaction(uint txId)
        public
        onlyOwner
        txExists(txId)
        txNotExecuted(txId)
    {
        require(approvals[txId][msg.sender], "Transaction not approved");
        approvals[txId][msg.sender] = false;
        transactions[txId].numApprovals--;
        emit RejectTransaction(msg.sender, txId);
    }

    function confirmTransaction(uint txId)
        public
        onlyOwner
        txExists(txId)
        txNotExecuted(txId)
    {
        Transaction storage transaction = transactions[txId];
        require(
            transaction.numApprovals >= requiredApprovals,
            "Not enough approvals"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit ConfirmTransaction(txId);
    }
}
