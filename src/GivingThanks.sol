// SPDX-License-Identifier: MIT

// @audit floating pragma types
pragma solidity ^0.8.0;

import "./CharityRegistry.sol";
// n The remappings had not been done well in the foundry.toml file
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GivingThanks is ERC721URIStorage {
    CharityRegistry public registry;
    uint256 public tokenCounter;
    // @audit owner should be immutable as it is only set in the constructor
    address public owner;

    // q is the registry parameter needed in this constructor?
    // @audit msg.sender is casted into the Chainregisrty contract. It is incorrect because msg.sender is not necessarily the address of the chain Registry contract. this breaks the intended functionality of the contract.
    constructor(address _registry) ERC721("DonationReceipt", "DRC") {
        registry = CharityRegistry(msg.sender);
        owner = msg.sender;
        tokenCounter = 0;
    }

    function donate(address charity) public payable {
        // q is the isVerified function in the registry checking if the contract is indeed verified?
        require(registry.isVerified(charity), "Charity not verified");
        (bool sent,) = charity.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _mint(msg.sender, tokenCounter);

        // Create metadata for the tokenURI
        string memory uri = _createTokenURI(msg.sender, block.timestamp, msg.value);
        _setTokenURI(tokenCounter, uri);

        tokenCounter += 1;
    }

    function _createTokenURI(address donor, uint256 date, uint256 amount) internal pure returns (string memory) {
        // Create JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"donor":"',
                Strings.toHexString(uint160(donor), 20),
                '","date":"',
                Strings.toString(date),
                '","amount":"',
                Strings.toString(amount),
                '"}'
            )
        );

        // Encode in base64 using OpenZeppelin's Base64 library
        string memory base64Json = Base64.encode(bytes(json));

        // Return the data URL
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    function updateRegistry(address _registry) public {
        registry = CharityRegistry(_registry);
    }
}
