// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CharityRegistry {
    address public admin;
    mapping(address => bool) public verifiedCharities;
    mapping(address => bool) public registeredCharities;

    constructor() {
        admin = msg.sender;
    }

    function registerCharity(address charity) public {
        registeredCharities[charity] = true;
    }

    function verifyCharity(address charity) public {
        require(msg.sender == admin, "Only admin can verify");
        require(registeredCharities[charity], "Charity not registered");
        verifiedCharities[charity] = true;
    }
    //@written-medium This function checks if a contract is registered and not verified as it is supposed to do.

    function isVerified(address charity) public view returns (bool) {
        return registeredCharities[charity];
    }
    // @written-low This function mis missing the 0 address validation check which could make the owner lose ownership of the contract.

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Only admin can change admin");
        admin = newAdmin;
    }
}
