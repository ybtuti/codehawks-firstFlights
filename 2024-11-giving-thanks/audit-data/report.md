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

## POC

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