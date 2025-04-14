// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MultiSigWallet {
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

    // Modifiers.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
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
}
